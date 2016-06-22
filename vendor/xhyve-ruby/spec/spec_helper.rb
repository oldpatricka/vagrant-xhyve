require 'simplecov'
SimpleCov.start

require 'securerandom'
require 'net/ssh'
require 'net/ping'
require File.expand_path('../../lib/xhyve.rb', __FILE__)

FIXTURE_PATH = File.expand_path('../../spec/fixtures', __FILE__)

#  def self.append_features(mod)
#    mod.class_eval %[
#      around(:each) do |example|
#        example.run
#      end
#    ]
#  end
# end

def ping(ip)
  attempts = 0
  max_attempts = 60
  sleep_time = 1

  while attempts < max_attempts
    attempts += 1
    sleep(sleep_time)
    begin
      return true if Net::Ping::ICMP.new(ip).ping
    rescue
    end
  end
end

def on_guest(ip, command)
  output = ''
  Net::SSH.start(ip, 'console', password: 'tcuser') do |ssh|
    output = ssh.exec!(command)
  end
  output.strip
end

RSpec.configure do |config|
  config.order = :defined
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
