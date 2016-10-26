require "log4r"

module VagrantPlugins
  module XHYVE
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app = app
          @env = env
          @logger = Log4r::Logger.new("vagrant_xhyve::action::read_state")
        end

        def call(env)

          env[:machine_state_id] = read_state(env)
          @app.call(env)
        end

        private

        def read_state(env)
          xhyve_status = read_xhyve_status_file(env)
          return :not_created if env[:machine].id.nil?
          env[:xhyve_status] = xhyve_status
          if process_alive(xhyve_status[:pid])
            return :running
          else
            return :stopped
          end
        end

        def read_xhyve_status_file(env)
          xhyve_status_file_path = File.join(env[:machine].data_dir, "xhyve.json")
          return {} unless File.exist?(xhyve_status_file_path)
          machine_json = File.read(xhyve_status_file_path)
          JSON.parse(machine_json, :symbolize_names => true)
        end

        def process_alive(pid)
          return false if pid.nil?
          begin
            Process.getpgid(pid.to_i)
            true
          rescue Errno::ESRCH
            false
          end
        end
      end
    end
  end
end
