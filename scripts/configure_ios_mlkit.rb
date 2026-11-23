require 'pathname'
require 'xcodeproj'

PROJECT_PATH = ENV.fetch('IOS_PROJECT', 'ios/Runner.xcodeproj')
TARGET_NAME = ENV.fetch('IOS_TARGET', 'Runner')
BUNDLES_DIR = ENV.fetch('MLKIT_BUNDLES_DIR', 'ios/mlkit_bundles')
FIREBASE_PLIST = 'ios/Runner/GoogleService-Info.plist'
BUNDLES = [
  'MLKitImageLabelingResources.bundle',
  'MLKitObjectDetectionCommonResources.bundle',
  'LatinOCRResources.bundle'
].freeze
LINKER_FLAGS = ['$(inherited)', '-ObjC', '-all_load'].freeze
PROJECT_DIR = File.dirname(PROJECT_PATH)

missing = BUNDLES.reject { |bundle| File.directory?(File.join(BUNDLES_DIR, bundle)) }
abort "Faltan bundles en #{BUNDLES_DIR}: #{missing.join(', ')}" unless missing.empty?
abort "Falta #{FIREBASE_PLIST}" unless File.file?(FIREBASE_PLIST)

def source_root_path(path, project_dir)
  Pathname.new(File.expand_path(path)).relative_path_from(
    Pathname.new(File.expand_path(project_dir))
  ).to_s
end

def add_resource(group, target, path, file_type, source_tree)
  file_ref = group.files.find { |file| file.path == path }
  file_ref ||= group.new_file(path)
  file_ref.last_known_file_type = file_type
  file_ref.source_tree = source_tree

  already_added = target.resources_build_phase.files.any? do |build_file|
    build_file.file_ref && build_file.file_ref.uuid == file_ref.uuid
  end
  target.add_resources([file_ref]) unless already_added
  file_ref
end

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |candidate| candidate.name == TARGET_NAME }
abort "No se encontró el target #{TARGET_NAME}" unless target

plist_path = source_root_path(FIREBASE_PLIST, PROJECT_DIR)
add_resource(project.main_group, target, plist_path, 'text.plist.xml', 'SOURCE_ROOT')
puts "Recurso: #{plist_path} (SOURCE_ROOT)"

target.build_configurations.each do |config|
  current = config.build_settings['OTHER_LDFLAGS'] || []
  current = current.split if current.is_a?(String)
  config.build_settings['OTHER_LDFLAGS'] = current + (LINKER_FLAGS - current)
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end

project.save
puts "Configurado #{TARGET_NAME}: plist, OTHER_LDFLAGS y deployment target actualizados"
