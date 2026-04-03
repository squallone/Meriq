#!/usr/bin/env ruby

require 'fileutils'
require 'xcodeproj'

root = File.expand_path('..', __dir__)
project_path = File.join(root, 'Meriq.xcodeproj')

FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes['LastUpgradeCheck'] = '2640'

app_group = project.main_group.new_group('Meriq', 'Sources/Meriq')
resources_group = app_group.new_group('Resources', 'Resources')

target = project.new_target(:application, 'Meriq', :osx, '14.0', project.products_group, :swift)

project.build_configurations.each do |configuration|
    configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '14.0'
    configuration.build_settings['SWIFT_VERSION'] = '6.0'
end

target.build_configurations.each do |configuration|
    configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.example.Meriq'
    configuration.build_settings['PRODUCT_NAME'] = 'Meriq'
    configuration.build_settings['SWIFT_VERSION'] = '6.0'
    configuration.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '14.0'
    configuration.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    configuration.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Meriq'
    configuration.build_settings['INFOPLIST_KEY_LSApplicationCategoryType'] = 'public.app-category.developer-tools'
    configuration.build_settings['INFOPLIST_KEY_NSHighResolutionCapable'] = 'YES'
    configuration.build_settings['INFOPLIST_KEY_NSPrincipalClass'] = 'NSApplication'
    configuration.build_settings['MARKETING_VERSION'] = '1.0'
    configuration.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    configuration.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
    configuration.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
        '$(inherited)',
        '@executable_path/../Frameworks'
    ]

    if configuration.name == 'Release'
        configuration.build_settings['ENABLE_HARDENED_RUNTIME'] = 'YES'
    end
end

source_files = %w[
    MeriqApp.swift
    MermaidConfiguration.swift
    ContentView.swift
    MermaidRenderEngine.swift
    MermaidRenderer.swift
].map { |file_name| app_group.new_file(file_name) }

target.add_file_references(source_files)

resource_files = %w[
    Assets.xcassets
    index.html
    mermaid.min.js
].map { |file_name| resources_group.new_file(file_name) }

resource_files.each do |file_reference|
    target.resources_build_phase.add_file_reference(file_reference, true)
end

project.root_object.attributes['TargetAttributes'] = {
    target.uuid => {
        'CreatedOnToolsVersion' => '26.4'
    }
}

project.save

workspace_dir = File.join(project_path, 'project.xcworkspace')
FileUtils.mkdir_p(workspace_dir)
File.write(
    File.join(workspace_dir, 'contents.xcworkspacedata'),
    <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Workspace
           version = "1.0">
           <FileRef
              location = "self:">
           </FileRef>
        </Workspace>
    XML
)

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.set_launch_target(target)
scheme.save_as(project_path, 'Meriq', true)
