require 'fork_buddy'

fb = ForkBuddy.new(socket: '/tmp/fork_buddy.sock', rails_env: 'test')

fb.acquire(:rspec_ready, rails_env: 'test')
