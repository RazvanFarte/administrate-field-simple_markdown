# frozen_string_literal: true

require_relative 'support/dummy_server'

namespace :bench do
  desc 'Measure Redcarpet rendering cost by document size'
  task :redcarpet do
    sh RbConfig.ruby, 'bench/redcarpet_bench.rb'
  end

  desc 'Measure Postgres storage and round-trip cost by document size'
  task :postgres do
    container = 'administrate-field-easymde-bench-pg'
    running = system('docker', 'inspect', container, out: File::NULL, err: File::NULL)

    unless running
      sh 'docker', 'run', '-d', '--rm', '--name', container,
         '-e', 'POSTGRES_PASSWORD=bench', '-e', 'POSTGRES_DB=bench',
         '-p', '55432:5432', 'postgres:18-alpine'
      sleep 5
    end

    begin
      sh RbConfig.ruby, 'bench/postgres_bench.rb'
    ensure
      sh 'docker', 'stop', container unless running
    end
  end

  desc 'Measure editor initialization cost against the number of fields on a page'
  task :browser do
    counts = ENV.fetch('EDITOR_COUNTS', '1,3,5,10,20').split(',')
    puts '| Content | Editors on page | DOMContentLoaded | All editors ready | ' \
         'DOM nodes | JS heap |'
    puts '|---|---|---|---|---|---|'

    counts.each do |count|
      DummyServer.run('EDITOR_FIELDS' => count) do
        DummyServer.playwright(%w[bench/browser_bench.mjs], 'EDITOR_FIELDS' => count)
      end
    end
  end
end
