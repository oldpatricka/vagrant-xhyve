require "log4r"

module VagrantPlugins
  module XHYVE
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::read_state")
        end

        def call(env)
          env[:machine_state_id] = read_state(env[:machine])

          @app.call(env)
        end

        def read_state(machine)
          return :not_created if machine.id.nil?

          xhyve_pid = Integer(machine.id)

          if process_alive(xhyve_pid) then
              return :running
          else
              return :stopped
          end
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
