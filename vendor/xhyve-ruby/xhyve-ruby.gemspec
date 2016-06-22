lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xhyve/version'

Gem::Specification.new do |s|
  s.name        = 'xhyve-ruby'
  s.version     = Xhyve::VERSION
  s.date        = '2015-11-23'
  s.summary     = 'Ruby wrapper for xhyve'
  s.description = 'Provides a means of interacting with xhyve from ruby'
  s.authors     = ['Dale Hamel']
  s.email       = 'dale.hamel@srvthe.net'
  s.files       = Dir['lib/**/*']
  s.homepage    =
    'https://github.com/dalehamel/xhyve-ruby'
  s.license       = 'MIT'
  s.add_development_dependency 'simplecov', ['=0.10.0']
  s.add_development_dependency 'rspec', ['=3.2.0']
  s.add_development_dependency 'net-ssh', ['=3.0.1']
  s.add_development_dependency 'net-ping', ['=1.7.8']
  s.add_development_dependency 'rake', ['=10.4.2']
  s.add_development_dependency 'rake-compiler', ['=0.9.5']
end
