require "log4r"
require "json"
require "fileutils"

module VagrantPlugins
  module XHYVE
    module Action
      # This terminates the running instance.
      class TerminateInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::terminate_instance")
        end

        def call(env)
          stop_instance(env)
          # Remove the tracking ID
          env[:ui].info(I18n.t("vagrant_xhyve.terminating"))
          FileUtils.rm_rf(env[:machine].data_dir)

          @app.call(env)
        end

        def stop_instance(env)
          halt_env = env.dup
          env[:action_runner].run(Action.action_halt, halt_env)
        end
      end
    end
  end
end
