require "log4r"

module VagrantPlugins
  module XHYVE
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_aws::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env)

          @app.call(env)
        end

        def read_ssh_info(env)
          return nil if env[:machine].id.nil?

          env[:ui].info("machine ip: #{env[:machine_ip]}")

          return { :host => env[:machine_ip], :port => 22 }
        end
      end
    end
  end
end
