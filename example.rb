require 'fork_buddy/server'

fbs = ForkBuddy::Server.start(socket: '/tmp/fork_buddy.sock') do
  stage :initial {
    option :rails_env
    stage :require_bundler {
      stage :require_application {
        stage :application_loaded {
          stage :rspec_ready
          stage :cucumber_ready
        }
      }
    }
  }
end

fbs.stage(:initial)

require 'rubygems'
require 'bundler'

fbs.stage(:require_bundler)

Bundler.require :default, fbs.option(:rails_env)

fbs.stage(:require_application)

ENV['RAILS_ENV'] = fbs.option(:rails_env)
require 'application and stuff'

fbs.stage(:application_booted)

fbs.stage(:rspec_ready) do
  require 'rspec/rails'
end

fbs.stage(:cucumber_ready) do
  require 'cucumber/rails'
end
