# frozen_string_literal: true

require 'net/http'
require 'timeout'
require 'rbconfig'

# Boots the dummy Administrate application in a child process for the browser
# suite and the browser benchmark, both of which drive a real page.
module DummyServer
  PORT = Integer(ENV.fetch('DUMMY_PORT', '3123'))
  BASE_URL = "http://127.0.0.1:#{PORT}".freeze
  BOOT_TIMEOUT = 60

  module_function

  def run(env = {})
    pid = spawn(
      env.transform_values(&:to_s),
      RbConfig.ruby, 'spec/dummy/bin/server', PORT.to_s,
      out: 'log/dummy-server.log', err: 'log/dummy-server.log'
    )
    wait_until_listening

    yield BASE_URL
  ensure
    if pid
      Process.kill('TERM', pid)
      Process.waitpid(pid)
    end
  end

  def wait_until_listening
    Timeout.timeout(BOOT_TIMEOUT) do
      loop do
        Net::HTTP.get_response(URI("#{BASE_URL}/admin/articles"))
        return true
      rescue StandardError
        sleep 0.5
      end
    end
  rescue Timeout::Error
    abort "dummy app did not start within #{BOOT_TIMEOUT}s; see log/dummy-server.log"
  end

  # The browsers live in the official Playwright image rather than on the
  # developer's machine, so nothing has to be installed to run these.
  def playwright(node_args, env = {})
    image = ENV.fetch('PLAYWRIGHT_IMAGE', 'mcr.microsoft.com/playwright:v1.57.0-noble')
    docker_env = env.flat_map { |key, value| ['-e', "#{key}=#{value}"] }

    system(
      'docker', 'run', '--rm', '--init', '--network', 'host',
      '-v', "#{Dir.pwd}:/work", '-w', '/work',
      '-e', "BASE_URL=#{BASE_URL}", *docker_env,
      image, 'node', *node_args
    )
  end
end
