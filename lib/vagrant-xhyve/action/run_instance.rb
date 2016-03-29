require "log4r"
require 'json'
require 'securerandom'
require 'xhyve'

require 'vagrant/util/retryable'

require 'vagrant-xhyve/util/timer'

module VagrantPlugins
  module XHYVE
    module Action
      # This runs the configured instance.
      class RunInstance
        include Vagrant::Util::Retryable
        puts "in RunInstance"

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

          vmlinuz_file = env[:machine].box.directory.join("vmlinuz").to_s
          initrd_file = env[:machine].box.directory.join("initrd.gz").to_s
          hdd_file = env[:machine].box.directory.join("hdd.img").to_s
          block_devices = []

          if File.exist?(hdd_file) then
              disk_kernel_parameters = "acpi=off root=/dev/vda1 ro"
              block_devices.push(hdd_file)
          else
              disk_kernel_parameters = ""
          end

          kernel_parameters = "\"earlyprintk=serial console=ttyS0 #{disk_kernel_parameters}\""

          firmware = "kexec,#{vmlinuz_file},#{initrd_file},#{kernel_parameters}"
          machine_uuid = SecureRandom.uuid
          #command = "xhyve -U #{machine_uuid} #{disk_parameters} -f #{firmware}"

          xhyve_guest = Xhyve::Guest.new(
              kernel: vmlinuz_file,
              initrd: initrd_file,
              cmdline: kernel_parameters,
              blockdevs: block_devices,
              serial: 'com1',
              memory: memory,
              processors: 1,
              networking: true,
              acpi: true
          )

          xhyve_pid = xhyve_guest.start

          #xhyve_pid = fork do
            #exec "#{command}"
            #Process.daemon()
          #end
          
          env[:ui].info(" Launched xhyve VM with PID #{xhyve_pid}, MAC: #{xhyve_guest.mac}, and IP #{xhyve_guest.ip}")
        
          # Immediately save the ID since it is created at this point.
          env[:machine].id = xhyve_pid
          env[:machine_uuid] = machine_uuid
          env[:machine_mac] = xhyve_guest.mac
          env[:machine_ip] = xhyve_guest.ip

          @logger.info("Time to instance ready: #{env[:metrics]["instance_ready_time"]}")
          #if !env[:interrupted]
            #env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              ## Wait for SSH to be ready.
              #env[:ui].info(I18n.t("vagrant_xhyve.waiting_for_ssh"))
              #network_ready_retries = 0
              #network_ready_retries_max = 10
              #while true
                # If we're interrupted then just back out
                #break if env[:interrupted]
                # When an ec2 instance comes up, it's networking may not be ready
                # by the time we connect.
                #begin
                  #break if env[:machine].communicate.ready?
                #rescue Exception => e
                  #if network_ready_retries < network_ready_retries_max then
                    #network_ready_retries += 1
                    #@logger.warn(I18n.t("vagrant_xhyve.waiting_for_ssh, retrying"))
                  #else
                    #raise e
                  #end
                #end
                #sleep 2
              #end
            #end

            #@logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_xhyve.ready"))
          #end

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

        def allows_ssh_port?(env, test_sec_groups, is_vpc)
          port = 22 # TODO get ssh_info port
          test_sec_groups = [ "default" ] if test_sec_groups.empty? # AWS default security group
          # filter groups by name or group_id (vpc)
          groups = test_sec_groups.map do |tsg|
            env[:aws_compute].security_groups.all.select { |sg| tsg == (is_vpc ? sg.group_id : sg.name) }
          end.flatten
          # filter TCP rules
          rules = groups.map { |sg| sg.ip_permissions.select { |r| r["ipProtocol"] == "tcp" } }.flatten
          # test if any range includes port
          !rules.select { |r| (r["fromPort"]..r["toPort"]).include?(port) }.empty?
        end

        def do_elastic_ip(env, domain, server, elastic_ip)
          if elastic_ip =~ /\d+\.\d+\.\d+\.\d+/
            begin
              address = env[:aws_compute].addresses.get(elastic_ip)
            rescue
              handle_elastic_ip_error(env, "Could not retrieve Elastic IP: #{elastic_ip}")
            end
            if address.nil?
              handle_elastic_ip_error(env, "Elastic IP not available: #{elastic_ip}")
            end
            @logger.debug("Public IP #{address.public_ip}")
          else
            begin
              allocation = env[:aws_compute].allocate_address(domain)
            rescue
              handle_elastic_ip_error(env, "Could not allocate Elastic IP.")
            end
            @logger.debug("Public IP #{allocation.body['publicIp']}")
          end

          # Associate the address and save the metadata to a hash
          h = nil
          if domain == 'vpc'
            # VPC requires an allocation ID to assign an IP
            if address
              association = env[:aws_compute].associate_address(server.id, nil, nil, address.allocation_id)
            else
              association = env[:aws_compute].associate_address(server.id, nil, nil, allocation.body['allocationId'])
              # Only store release data for an allocated address
              h = { :allocation_id => allocation.body['allocationId'], :association_id => association.body['associationId'], :public_ip => allocation.body['publicIp'] }
            end
          else
            # Standard EC2 instances only need the allocated IP address
            if address
              association = env[:aws_compute].associate_address(server.id, address.public_ip)
            else
              association = env[:aws_compute].associate_address(server.id, allocation.body['publicIp'])
              h = { :public_ip => allocation.body['publicIp'] }
            end
          end

          unless association.body['return']
            @logger.debug("Could not associate Elastic IP.")
            terminate(env)
            raise Errors::FogError,
                            :message => "Could not allocate Elastic IP."
          end

          # Save this IP to the data dir so it can be released when the instance is destroyed
          if h 
            ip_file = env[:machine].data_dir.join('elastic_ip')
            ip_file.open('w+') do |f|
              f.write(h.to_json)
            end
          end
        end

        def handle_elastic_ip_error(env, message) 
          @logger.debug(message)
          terminate(env)
          raise Errors::FogError,
                          :message => message
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
