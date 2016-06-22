require 'xhyve'

module VagrantPlugins
  module XHYVE
    module Util
      
      # TODO: send all this upstream
      class XhyveGuest < Xhyve::Guest

        def initialize(**opts)
          @xhyve_binary = opts[:xhyve_binary] || Xhyve::BINARY_PATH
          if opts.has_key? "pid"
            @pid = pid
          else
            @kernel = opts.fetch(:kernel)
            @initrd = opts.fetch(:initrd)
            @cmdline = opts.fetch(:cmdline)
            @blockdevs = [opts[:blockdevs] || []].flatten
            @memory = opts[:memory] || '500M'
            @processors = opts[:processors] || '1'
            @uuid = opts[:uuid] || SecureRandom.uuid
            @serial = opts[:serial] || 'com1'
            @acpi = opts[:acpi] || true
            @networking = opts[:networking] || true
            @foreground = opts[:foreground] || false
            @command = build_command
            @mac = find_mac
          end

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
            :xhyve_binary => @xhyve_binary
          }
        end

        def build_command
          [
            "#{@xhyve_binary}",
            "#{'-A' if @acpi}",
            '-U', @uuid,
            '-m', @memory,
            '-c', @processors,
            '-s', '0:0,hostbridge',
            "#{"-s #{PCI_BASE - 1}:0,virtio-net" if @networking }" ,
            "#{"#{@blockdevs.each_with_index.map { |p, i| "-s #{PCI_BASE + i},virtio-blk,#{p}" }.join(' ')}" unless @blockdevs.empty? }",
            '-s', '31,lpc',
            '-l', "#{@serial},stdio",
            '-f' "kexec,#{@kernel},#{@initrd},'#{@cmdline}'"
          ].join(' ')
        end
      end
    end
  end
end
