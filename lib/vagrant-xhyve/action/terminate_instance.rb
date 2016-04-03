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
          xhyve_pid = env[:machine].id

          if xhyve_pid == nil then
            @logger.debug("xhyve already gone")
          elsif process_alive(Integer(xhyve_pid)) then
            env[:ui].info(" Terminating xhyve instance with PID #{xhyve_pid}")
            Process.kill(3, Integer(xhyve_pid))
          else
            @logger.debug("xhyve PID already gone #{xhyve_pid}")
          end

          # Destroy the server and remove the tracking ID
          env[:ui].info(I18n.t("vagrant_xhyve.terminating"))
          env[:machine].id = nil

          FileUtils.rm_rf(env[:machine].data_dir)

          @app.call(env)
        end

        def process_alive(pid)
          begin
            Process.getpgid(pid)
            true
          rescue Errno::ESRCH
            false
          end
        end
      end
    end
  end
end
