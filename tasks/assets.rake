# frozen_string_literal: true

namespace :assets do
  desc 'Rebuild app/assets/builds from the vendored EasyMDE and this gem\'s sources'
  task :build do
    sh 'node', 'build/build_assets.mjs'
  end

  desc 'Vendor a different EasyMDE release, e.g. rake assets:vendor[2.21.0]'
  task :vendor, [:version] do |_task, args|
    version = args.fetch(:version)
    sh 'npm', 'install', '--no-audit', '--no-fund', "easymde@#{version}"
    sh 'cp', 'node_modules/easymde/dist/easymde.min.js', 'vendor/easymde/easymde.min.js'
    sh 'cp', 'node_modules/easymde/dist/easymde.min.css', 'vendor/easymde/easymde.min.css'
    File.write('vendor/easymde/VERSION', "#{version}\n")
    Rake::Task['assets:build'].invoke
  end
end
