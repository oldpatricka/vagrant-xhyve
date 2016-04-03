require "log4r"

module VagrantPlugins
  module XHYVE
    module Action
      # This stops the running instance.
      class StopInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::stop_instance")
        end

        def call(env)
          if env[:machine].state.id == :stopped
            env[:ui].info(I18n.t("vagrant_xhyve.already_status", :status => env[:machine].state.id))
          else
              env[:ui].info(I18n.t("vagrant_xhyve.stopping"))

              xhyve_pid = env[:machine].id

              if xhyve_pid == nil then
                @logger.debug("xhyve already gone")
              elsif process_alive(Integer(xhyve_pid)) then
                env[:ui].info(" Terminating xhyve instance with PID #{xhyve_pid}")
                Process.kill(3, Integer(xhyve_pid))
              else
                @logger.debug("xhyve PID already gone #{xhyve_pid}")
              end
          end

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
