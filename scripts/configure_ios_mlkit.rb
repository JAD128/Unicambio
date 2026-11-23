require 'xcodeproj'

PROJECT_PATH = ENV.fetch('IOS_PROJECT', 'ios/Runner.xcodeproj')
TARGET_NAME = ENV.fetch('IOS_TARGET', 'Runner')
BUNDLES_DIR = ENV.fetch('MLKIT_BUNDLES_DIR', 'ios/Runner/Resources/Bundles')
BUNDLES = [
  'MLKitImageLabelingResources.bundle',
  'MLKitObjectDetectionCommonResources.bundle',
  'LatinOCRResources.bundle'
].freeze
LINKER_FLAGS = ['$(inherited)', '-ObjC', '-all_load'].freeze

missing = BUNDLES.reject { |bundle| File.directory?(File.join(BUNDLES_DIR, bundle)) }
abort "Faltan bundles en #{BUNDLES_DIR}: #{missing.join(', ')}" unless missing.empty?

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |candidate| candidate.name == TARGET_NAME }
abort "No se encontró el target #{TARGET_NAME}" unless target

runner_group = project.main_group.children.find do |group|
  group.respond_to?(:path) && group.path == 'Runner'
end
runner_group ||= project.main_group.find_subpath('Runner', true)
bundles_group = runner_group.find_subpath('Resources/Bundles', true)

BUNDLES.each do |bundle|
  file_ref = bundles_group.files.find { |file| file.path == bundle }
  file_ref ||= bundles_group.new_file(bundle)
  file_ref.last_known_file_type = 'wrapper.bundle'

  already_added = target.resources_build_phase.files.any? do |build_file|
    build_file.file_ref && build_file.file_ref.uuid == file_ref.uuid
  end
  target.add_resources([file_ref]) unless already_added
end

target.build_configurations.each do |config|
  current = config.build_settings['OTHER_LDFLAGS'] || []
  current = current.split if current.is_a?(String)
  config.build_settings['OTHER_LDFLAGS'] = current + (LINKER_FLAGS - current)
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
end

project.save
puts "Configurado #{TARGET_NAME}: bundles y OTHER_LDFLAGS actualizados"
