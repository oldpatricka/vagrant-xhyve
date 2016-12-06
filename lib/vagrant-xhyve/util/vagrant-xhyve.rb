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
            "#{"#{@blockdevs.each_with_index.map { |p, i| "-s #{PCI_BASE + i},virtio-blk,#{p}" }.join(' ')}" unless @blockdevs.empty? }",
            '-s', '31,lpc',
            '-l', "#{@serial},stdio",
            '-f', "kexec,#{@kernel},#{@initrd},'#{@cmdline}'"
          ].join(' ')
        end
      end
    end
  end
end
