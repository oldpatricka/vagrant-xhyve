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
          if is_process_alive? pid(env)
            env[:ui].info(I18n.t("vagrant_xhyve.stopping"))
            kill_xhyve_process(env)
          else
            env[:ui].info(I18n.t("vagrant_xhyve.already_status", status: env[:machine].state.id))
          end
          destroy_xhyve_status_file(env)
          @app.call(env)
        end

        def is_process_alive?(pid)
          return false if pid == 0
          begin
            Process.getpgid(pid)
            true
          rescue Errno::ESRCH
            false
          end
        end

        def kill_xhyve_process(env)
          Process.kill(3, pid(env))
        end

        def destroy_xhyve_status_file(env)
          xhyve_status_file_path = File.join(env[:machine].data_dir, "xhyve.json")
          FileUtils.remove_file(xhyve_status_file_path, force: true)
        end

        def pid(env)
          @pid ||= env[:xhyve_status][:pid].to_i
        end
      end
    end
  end
end
