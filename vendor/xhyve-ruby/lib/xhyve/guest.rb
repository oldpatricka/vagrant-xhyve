require 'securerandom'
require 'io/console'

require 'xhyve/dhcp'

module Xhyve
  BINARY_PATH = File.expand_path('../../../lib/xhyve/vendor/xhyve', __FILE__).freeze

  # An object to represent a guest that we can start and stop
  # Effectively, it's a command wrapper around xhyve to provide an
  # object oriented interface to a hypervisor guest
  class Guest
    PCI_BASE = 3
    NULLDEV = '/dev/null'

    attr_reader :pid, :uuid, :mac

    def initialize(**opts)
      @kernel = opts.fetch(:kernel)
      @initrd = opts.fetch(:initrd)
      @cmdline = opts.fetch(:cmdline)
      @blockdevs = [opts[:blockdevs] || []].flatten
      @memory = opts[:memory] || '500M'
      @processors = opts[:processors] || '1'
      @uuid = opts[:uuid] || SecureRandom.uuid
      @serial = opts[:serial] || 'com1'
      @acpi = opts.fetch(:acpi, true)
      @networking = opts.fetch(:networking, true)
      @foreground = opts[:foreground] || false
      @binary = opts[:binary] || BINARY_PATH
      @command = build_command
      @mac = find_mac
    end

    def start
      outfile, infile = redirection
      @pid = spawn(@command, [:out, :err] => outfile, in: infile)
      if @foreground
        Process.wait(@pid) 
        outfile.cooked!
        infile.cooked!
      end
      @pid
    end

    def stop
      Process.kill('KILL', @pid)
    end

    def running?
      (true if Process.kill(0, @pid) rescue false)
    end

    def ip
      @ip ||= Xhyve::DHCP.get_ip_for_mac(@mac)
    end

    private

    def redirection
      if @foreground
        [$stdout.raw!, $stdin.raw! ]
      else
        [NULLDEV, NULLDEV]
      end
    end

    def find_mac
      `#{@command} -M`.strip.gsub(/MAC:\s+/,'')
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
        '-f' "kexec,#{@kernel},#{@initrd},'#{@cmdline}'"
      ].join(' ')
    end
  end
end
