require "log4r"
require 'vagrant-xhyve/util/vagrant-xhyve'

module VagrantPlugins
  module XHYVE
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          machine_info_path = File.join(env[:machine].data_dir, "xhyve.json")
          machine_json = File.read(machine_info_path)
          machine_options = JSON.parse(machine_json, :symbolize_names => true)

          return { :host => machine_options[:ip], :port => 22 }
        end
      end
    end
  end
end
