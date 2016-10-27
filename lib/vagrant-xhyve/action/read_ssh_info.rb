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
          xhyve_status = env[:xhyve_status]
          return { :host => xhyve_status[:ip], :port => 22 }
        end
      end
    end
  end
end
