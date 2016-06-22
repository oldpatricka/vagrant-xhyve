module Xhyve
  # Parse DHCP leases file for a MAC address, and get its ip.
  module DHCP
    extend self
    LEASES_FILE = '/var/db/dhcpd_leases'
    WAIT_TIME = 1
    MAX_ATTEMPTS = 60

    def get_ip_for_mac(mac)
      max = ENV.key?('MAX_IP_WAIT') ? ENV['MAX_IP_WAIT'].to_i : nil
      ip = wait_for(max: max) do
        ip = parse_lease_file_for_mac(mac)
      end
    end

    def parse_lease_file_for_mac(mac)
      lease_file = (ENV['LEASES_FILE'] || LEASES_FILE)
      contents = wait_for do
        File.read(lease_file) if File.exists?(lease_file)
      end
      pattern = contents.match(/ip_address=(\S+)\n\thw_address=\d+,#{mac}/)
      if pattern
        addrs = pattern.captures
        addrs.first if addrs
      end
    end

  private

    def wait_for(max: nil)
      attempts = 0
      max ||= MAX_ATTEMPTS
      while attempts < max
        attempts += 1
        result = yield
        return result if result
        sleep(WAIT_TIME)
      end
    end
  end
end
