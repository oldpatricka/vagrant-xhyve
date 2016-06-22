require 'rake/extensiontask'
require 'rspec/core/rake_task'
require 'fileutils'

XHYVE_TMP = 'tmp/xhyve'

# Compile native extensions task
Rake::ExtensionTask.new 'vmnet' do |ext|
  ext.lib_dir = 'lib/xhyve/vmnet'
end

# Spec test
RSpec::Core::RakeTask.new(:spec)

desc 'Build xhyve binary'
task :vendor do
  Dir.chdir('tmp') do
    unless Dir.exist?('xhyve/.git')
      system('git clone https://github.com/mist64/xhyve.git') || fail('Could not clone xhyve')
    end
    Dir.chdir('xhyve') do
      system('git fetch') || fail('Could not fetch')
      system('git reset --hard origin/master') || fail('Could not reset head')
      system('make') || fail('Make failed')
    end
  end
  FileUtils.mkdir_p('lib/xhyve/vendor')
  FileUtils.cp('tmp/xhyve/build/xhyve', 'lib/xhyve/vendor')
end

desc 'Build the ruby gem'
task :build do
  system('gem build xhyve-ruby.gemspec') || fail('Failed to build gem')
end

desc 'Install gem'
task install: :build do
  system('gem install xhyve-ruby*.gem') || fail('Couldn not install gem')
end

# Deps and defaults
task default: :spec
