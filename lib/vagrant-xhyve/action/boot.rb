require "log4r"
require 'json'
require 'securerandom'

require 'vagrant/util/retryable'

require 'vagrant-xhyve/util/timer'
require 'vagrant-xhyve/util/vagrant-xhyve'

module VagrantPlugins
  module XHYVE
    module Action
      # This runs the configured instance.
      class Boot
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(" About to launch vm...")
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          machine_info_path = File.join(env[:machine].data_dir, "xhyve.json")
          if File.exist?(machine_info_path)
            machine_json = File.read(machine_info_path)
            machine_options = JSON.parse(machine_json, :symbolize_names => true)
            log.debug "Machine Options: #{JSON.pretty_generate(machine_options)}"
            machine_uuid = machine_options[:uuid]
            pid = machine_options[:pid]
            mac = machine_options[:mac]
          else
            machine_uuid = SecureRandom.uuid
          end

          guest_config = {
            pid: pid,
            mac: mac,
            uuid: machine_uuid,
            cmdline: kernel_command(env),
            memory: memory(env),
            processors: cpus(env),
            binary: xhyve_binary(env),
          }

          xhyve_guest = start_guest(env, guest_config)
          # Immediately save the ID since it is created at this point.
          env[:machine].id = xhyve_guest.uuid

          save_guest_status(env, xhyve_guest)
          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end

        private

        def block_device_paths(base_path)
          block_paths = Dir.glob File.join(base_path, "block*.{raw,img,qcow,qcow2}")
          block_paths.sort
        end

        def kernel_file_path(base_path)
          File.join(base_path, "vmlinuz")
        end

        def initrd_file_path(base_path)
          File.join(base_path, "initrd.gz")
        end

        def memory(env)
          provider_config(env).memory
        end

        def cpus(env)
          provider_config(env).cpus
        end

        def xhyve_binary(env)
          provider_config(env).xhyve_binary
        end

        def kernel_command(env)
          provider_config(env).kernel_command
        end

        def provider_config(env)
          @provider_config ||= env[:machine].provider_config
        end

        def start_guest(env, config = {})
          image_dir = File.join(env[:machine].data_dir, "image")
          default_config = {
            kernel: kernel_file_path(image_dir),
            initrd: initrd_file_path(image_dir),
            blockdevs: block_device_paths(image_dir),
            serial: 'com1',
            networking: true,
            acpi: true
          }
          config = default_config.merge(config)
          log.debug "xhyve configuration: #{JSON.pretty_generate(config)}"
          xhyve_guest = Util::XhyveGuest.new config
          xhyve_guest.start
          xhyve_guest
        end

        def save_guest_status(env, guest)
          wait_for_guest_ip(env, guest)
          machine_info_path = File.join(env[:machine].data_dir, "xhyve.json")
          log.debug "xhyve configuration: #{JSON.pretty_generate(guest.options)}"
          File.write(machine_info_path, guest.options().to_json)
          log.info(" Launched xhyve VM with PID #{guest.pid}, MAC: #{guest.mac}, and IP #{guest.ip}")
        end

        def wait_for_guest_ip(env, guest)
          network_ready_retries = 0
          network_ready_retries_max = 3
          update_xhyve_status(env, guest.options)
          while guest.ip.nil?
            break if env[:interrupted]

            if network_ready_retries < network_ready_retries_max then
              network_ready_retries += 1
              env[:ui].info("Waiting for IP to be ready. Try #{network_ready_retries}/#{network_ready_retries_max}...")
            else
              raise 'Waited too long for IP to be ready. Your VM probably did not boot.'
            end
            sleep 0.5
          end
          update_xhyve_status(env, guest.options)
        end

        def update_xhyve_status(env, status)
          env[:xhyve_status] = status
        end

        def log
          @logger ||= Log4r::Logger.new("vagrant_xhyve::action::boot")
        end
      end
    end
  end
end
