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
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::run_instance")
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          env[:ui].info(" About to launch vm")
          
          memory = env[:machine].provider_config.memory
          cpus = env[:machine].provider_config.cpus

          # Launch!
          env[:ui].info(" -- CPUs: #{cpus}") if cpus
          env[:ui].info(" -- Memory: #{memory}")

          machine_info_path = File.join(env[:machine].data_dir, "xhyve.json")
          if File.exist?(machine_info_path) then
            machine_json = File.read(machine_info_path)
            machine_options = JSON.parse(machine_json, :symbolize_names => true)
            machine_uuid = machine_options[:uuid]
            @logger.debug("Found existing UUID: #{machine_uuid}")
          else
            machine_uuid = SecureRandom.uuid
            @logger.debug("Created new UUID: #{machine_uuid}")
          end

          image_dir = File.join(env[:machine].data_dir, "image")
          vmlinuz_file = File.join(image_dir, "vmlinuz")
          initrd_file = File.join(image_dir, "initrd.gz")
          block_devices = []

          0.upto(10).each do |blockidx|
            block_file = File.join(image_dir, "block#{blockidx}.img")
            if (File.exist? block_file) then
              @logger.debug("Found block device #{block_file}")
              block_devices.push(block_file)
            else
              break
            end
          end

          if block_devices.any? then
              disk_kernel_parameters = "acpi=off root=/dev/vda1 ro"
          else
              disk_kernel_parameters = ""
          end

          kernel_parameters = "\"earlyprintk=serial console=ttyS0 #{disk_kernel_parameters}\""

          firmware = "kexec,#{vmlinuz_file},#{initrd_file},#{kernel_parameters}"

          @logger.debug("Machine data_dir: #{env[:machine].data_dir}")
          @logger.debug("Kernel Options: #{kernel_parameters}")
          @logger.debug("Block Devices: #{block_devices}")

          xhyve_guest = Util::XhyveGuest.new(
              kernel: vmlinuz_file,
              initrd: initrd_file,
              cmdline: kernel_parameters,
              blockdevs: block_devices,
              serial: 'com1',
              memory: memory,
              processors: cpus,
              networking: true,
              acpi: true
          )


          xhyve_pid = xhyve_guest.start
          env[:ui].info(xhyve_guest.options().to_json)
        
          # Immediately save the ID since it is created at this point.
          env[:machine].id = xhyve_pid

          # wait for ip
          network_ready_retries = 0
          network_ready_retries_max = 10
          while true
            break if env[:interrupted]

            if xhyve_guest.ip
                break
            end
            if network_ready_retries < network_ready_retries_max then
                network_ready_retries += 1
                env[:ui].info("Waiting for IP to be ready...")
            else
                raise 'Waited too long for IP to be ready.'
            end
            sleep 2
          end

          machine_info_path = File.join(env[:machine].data_dir, "xhyve.json")
          File.write(machine_info_path, xhyve_guest.options().to_json)
          
          @logger.info(" Launched xhyve VM with PID #{xhyve_pid}, MAC: #{xhyve_guest.mac}, and IP #{xhyve_guest.ip}")

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
      end
    end
  end
end
