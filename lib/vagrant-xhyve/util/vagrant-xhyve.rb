require 'xhyve'

module VagrantPlugins
  module XHYVE
    module Util
      # TODO: send all this upstream
      class XhyveGuest < Xhyve::Guest

        def initialize(**opts)
          super.tap do |s|
            @pid = opts.fetch(:pid, nil)
            @mac = opts[:mac] unless opts[:mac].nil?
          end
        end

        def start
          return @pid if running?
          super
        end

        def options
          {
            :pid => @pid,
            :kernel => @kernel,
            :initrd => @initrd,
            :cmdline => @cmdline,
            :blockdevs => @blockdevs,
            :memory => @memory,
            :processors => @processors,
            :uuid => @uuid,
            :serial => @serial,
            :acpi => @acpi,
            :networking => @networking,
            :foreground => @foreground,
            :command => @command,
            :mac => @mac,
            :ip => ip,
            :binary => @binary
            :vmtype => @vmtype
          }
        end

        def build_command
          [
            "#{@binary}",
            "#{'-A' if @acpi}",
            '-U', @uuid,
            '-m', @memory,
            '-c', @processors,
            '-s', '0:0,hostbridge',
            "#{"-s #{PCI_BASE - 1}:0,virtio-net" if @networking }" ,
            "#{build_block_device_parameter}",
            '-s', '31,lpc',
            '-l', "#{@serial},stdio",
            '-f', "#{@vmtype},#{@kernel},#{@initrd},'#{@cmdline}'"
          ].join(' ')
        end

        def build_block_device_parameter
          block_device_parameter = ""
          @blockdevs.each_with_index.map do |p, i|
            if p.include? "qcow"
              block_device_parameter << "-s #{PCI_BASE + i},virtio-blk,file://#{p},format\=qcow "
            else
              block_device_parameter << "-s #{PCI_BASE + i},virtio-blk,#{p} "
            end
          end
          block_device_parameter
        end
      end
    end
  end
end
