import { createRemoteJWKSet, jwtVerify } from 'jose';

const CATEGORIAS = [
  'libros',
  'apuntes',
  'tecnologia',
  'ropa',
  'hogar',
  'deportes',
  'otros',
];
const TIPOS = ['venta', 'intercambio', 'regalo'];
const MIME_PERMITIDOS = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
]);
const MAX_BODY = 4000000;
const MAX_IMAGEN_BASE64 = 3000000;
const JWKS = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);
const limites = new Map();

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Max-Age': '86400',
};

function json(cuerpo, estado = 200) {
  return new Response(JSON.stringify(cuerpo), {
    status: estado,
    headers: {
      ...cors,
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  });
}

function error(estado, codigo, mensaje) {
  return json({ error: codigo, mensaje }, estado);
}

function limpiarTexto(valor, maximo) {
  if (typeof valor !== 'string') return null;
  const limpio = valor.replace(/\s+/g, ' ').trim();
  if (limpio.length === 0 || limpio.length > maximo) return null;
  return limpio;
}

function listaTextos(valor, maximo, cantidad) {
  if (!Array.isArray(valor)) return [];
  return valor
    .map((entrada) =>
      typeof entrada === 'object' && entrada !== null
        ? `${entrada.etiqueta ?? ''} ${entrada.confianza ?? ''}`
        : entrada,
    )
    .map((texto) => limpiarTexto(texto, maximo))
    .filter((texto) => texto !== null)
    .slice(0, cantidad);
}

async function verificarToken(token, proyecto) {
  const ahora = Math.floor(Date.now() / 1000);
  const { payload } = await jwtVerify(token, JWKS, {
    algorithms: ['RS256'],
    audience: proyecto,
    issuer: `https://securetoken.google.com/${proyecto}`,
    clockTolerance: 5,
  });
  if (
    typeof payload.sub !== 'string' ||
    payload.sub.length === 0 ||
    payload.sub.length > 128
  ) {
    throw new Error('sub inválido');
  }
  if (typeof payload.iat !== 'number' || payload.iat > ahora + 5) {
    throw new Error('iat inválido');
  }
  if (typeof payload.auth_time !== 'number' || payload.auth_time > ahora + 5) {
    throw new Error('auth_time inválido');
  }
  return payload.sub;
}

function permitePeticion(uid, ip) {
  const clave = `${uid}:${ip}`;
  const ahora = Date.now();
  const entrada = limites.get(clave);
  if (entrada === undefined || ahora > entrada.fin) {
    limites.set(clave, { fin: ahora + 60000, cantidad: 1 });
    if (limites.size > 5000) limites.clear();
    return true;
  }
  if (entrada.cantidad >= 10) return false;
  entrada.cantidad += 1;
  return true;
}

function construirPrompt({ tipo, etiquetas, lineas }) {
  const categorias = CATEGORIAS.join(', ');
  const contextoEtiquetas = etiquetas.length > 0 ? etiquetas.join('; ') : 'ninguna';
  const contextoTexto = lineas.length > 0 ? lineas.join('; ') : 'ninguno';
  return [
    'Eres el asistente de UniCambio, un marketplace de artículos entre estudiantes universitarios.',
    `El usuario publicará como: ${tipo}.`,
    `Categorías permitidas (devuelve exactamente una): ${categorias}.`,
    `Etiquetas de visión local: ${contextoEtiquetas}.`,
    `Texto detectado por OCR: ${contextoTexto}.`,
    'Analiza la foto y devuelve un JSON con categoria, titulo y descripcion.',
    'Reglas:',
    '- Escribe siempre en español neutro y claro.',
    '- El título debe tener entre 3 y 60 caracteres, ser concreto y nombrar el artículo.',
    '- La descripción debe tener entre 40 y 220 caracteres y ayudar a quien compra, intercambia o recibe.',
    '- No inventes precio, estado, marca, garantía, ubicación, correos ni teléfonos.',
    '- No menciones que usaste etiquetas, OCR ni inteligencia artificial.',
    '- Si la foto es ambigua, sé conservador y elige "otros" cuando ninguna categoría encaje.',
    '- Devuelve solo el JSON válido, sin texto adicional ni bloques de código.',
  ].join('\n');
}

function extraerTexto(datos) {
  if (typeof datos.output_text === 'string') return datos.output_text;
  const salidas = Array.isArray(datos.outputs) ? datos.outputs : [];
  for (const salida of salidas.slice().reverse()) {
    if (typeof salida?.text === 'string') return salida.text;
    if (Array.isArray(salida?.content)) {
      const parte = salida.content.find(
        (elemento) => elemento?.type === 'text' && typeof elemento.text === 'string',
      );
      if (parte !== undefined) return parte.text;
    }
  }
  const pasos = Array.isArray(datos.steps) ? datos.steps : [];
  for (const paso of pasos.slice().reverse()) {
    const contenido = Array.isArray(paso?.content) ? paso.content : [];
    for (const parte of contenido) {
      if (parte?.type === 'text' && typeof parte.text === 'string') {
        return parte.text;
      }
    }
  }
  return null;
}

function validarSugerencia(texto) {
  const limpio = texto
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/```$/, '')
    .trim();
  const datos = JSON.parse(limpio);
  if (!CATEGORIAS.includes(datos.categoria)) {
    throw new Error('categoría no permitida');
  }
  const titulo = limpiarTexto(datos.titulo, 80);
  const descripcion = limpiarTexto(datos.descripcion, 300);
  if (titulo === null || titulo.length < 3) throw new Error('título inválido');
  if (descripcion === null || descripcion.length < 20) {
    throw new Error('descripción inválida');
  }
  if (
    /[\w.+-]+@[\w-]+\.[\w.-]+/.test(descripcion) ||
    /(?:\+?57)?\s*[3-9]\d{9}/.test(descripcion) ||
    /[$€£]/.test(descripcion)
  ) {
    throw new Error('descripción con datos prohibidos');
  }
  return { categoria: datos.categoria, titulo, descripcion };
}

async function manejarSugerencias(request, env) {
  const apiKey = env.GEMINI_API_KEY;
  if (typeof apiKey !== 'string' || apiKey.length === 0) {
    return error(500, 'sin_key', 'Falta el secreto GEMINI_API_KEY');
  }

  const autorizacion = request.headers.get('Authorization') ?? '';
  const token = autorizacion.startsWith('Bearer ')
    ? autorizacion.slice(7).trim()
    : '';
  if (token.length === 0) {
    return error(401, 'sin_token', 'Falta el ID token de Firebase');
  }

  const proyecto = env.FIREBASE_PROJECT_ID ?? 'unicambio-2f543';
  let uid;
  try {
    uid = await verificarToken(token, proyecto);
  } catch (_) {
    return error(401, 'token_invalido', 'El ID token de Firebase no es válido');
  }

  const ip = request.headers.get('CF-Connecting-IP') ?? 'local';
  if (!permitePeticion(uid, ip)) {
    return error(429, 'rate_limit', 'Demasiadas solicitudes; intenta de nuevo en un minuto');
  }

  const crudo = await request.text();
  if (crudo.length > MAX_BODY) {
    return error(413, 'cuerpo_grande', 'La solicitud es demasiado grande');
  }
  let entrada;
  try {
    entrada = JSON.parse(crudo);
  } catch (_) {
    return error(400, 'json_invalido', 'El cuerpo de la solicitud no es JSON válido');
  }

  const imagenBase64 =
    typeof entrada.imagenBase64 === 'string' ? entrada.imagenBase64.trim() : '';
  if (imagenBase64.length === 0 || imagenBase64.length > MAX_IMAGEN_BASE64) {
    return error(400, 'imagen_invalida', 'La imagen base64 no es válida');
  }
  const mimeType = MIME_PERMITIDOS.has(entrada.mimeType)
    ? entrada.mimeType
    : 'image/jpeg';
  const tipo = TIPOS.includes(entrada.tipoPublicacion)
    ? entrada.tipoPublicacion
    : 'venta';
  const etiquetas = listaTextos(entrada.etiquetas, 80, 30);
  const lineas = listaTextos(entrada.lineasTexto, 120, 20);
  const modelo = env.MODELO ?? 'gemini-3.5-flash-lite';

  const cuerpoGemini = {
    model: modelo,
    input: [
      { type: 'text', text: construirPrompt({ tipo, etiquetas, lineas }) },
      { type: 'image', data: imagenBase64, mime_type: mimeType },
    ],
    response_format: {
      type: 'text',
      mime_type: 'application/json',
      schema: {
        type: 'object',
        properties: {
          categoria: { type: 'string', enum: CATEGORIAS },
          titulo: { type: 'string' },
          descripcion: { type: 'string' },
        },
        required: ['categoria', 'titulo', 'descripcion'],
        additionalProperties: false,
      },
    },
    generation_config: {
      thinking_level: 'minimal',
      max_output_tokens: 300,
    },
    store: false,
  };

  let respuesta;
  try {
    respuesta = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/interactions',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
          'Api-Revision': '2026-05-20',
        },
        body: JSON.stringify(cuerpoGemini),
        signal: AbortSignal.timeout(25000),
      },
    );
  } catch (_) {
    return error(502, 'gemini_no_disponible', 'No se pudo contactar con Gemini');
  }

  if (respuesta.status === 429) {
    return error(503, 'cuota_agotada', 'La cuota de Gemini está agotada');
  }
  if (!respuesta.ok) {
    return error(502, 'gemini_error', `Gemini respondió ${respuesta.status}`);
  }

  let datos;
  try {
    datos = await respuesta.json();
  } catch (_) {
    return error(502, 'respuesta_invalida', 'Gemini no devolvió JSON válido');
  }
  const texto = extraerTexto(datos);
  if (texto === null) {
    return error(502, 'respuesta_vacia', 'Gemini no devolvió texto');
  }
  try {
    return json(validarSugerencia(texto));
  } catch (_) {
    return error(502, 'formato_invalido', 'La sugerencia de Gemini no es válida');
  }
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    const url = new URL(request.url);
    if (
      request.method === 'GET' &&
      (url.pathname === '/' || url.pathname === '/health')
    ) {
      return json({
        ok: true,
        modelo: env.MODELO ?? 'gemini-3.5-flash-lite',
        proyecto: env.FIREBASE_PROJECT_ID ?? 'unicambio-2f543',
      });
    }
    if (request.method === 'POST' && url.pathname === '/sugerencias') {
      return manejarSugerencias(request, env);
    }
    return error(404, 'no_encontrado', 'Ruta no encontrada');
  },
};
