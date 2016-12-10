module Xhyve
  # Parse DHCP leases file for a MAC address, and get its ip.
  module DHCP
    extend self
    LEASES_FILE = '/var/db/dhcpd_leases'
    WAIT_TIME = 1
    MAX_ATTEMPTS = 60

    def get_ip_for_mac(mac)
      normalized_mac = normalize_mac(mac)

      max = ENV.key?('MAX_IP_WAIT') ? ENV['MAX_IP_WAIT'].to_i : nil
      ip = wait_for(max: max) do
        ip = parse_lease_file_for_mac(normalized_mac)
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

    # macos dhcp represents mac addresses differently from xhyve. Specifically, 
    # it doesn't display leading zeros. This function normalized the mac
    # address to the macos format
    def normalize_mac(mac)
        # don't try to normalize if it doesn't seem like a mac...
        return mac if mac !~ /.*:.*:.*:.*:.*:.*/
        mac_parts = mac.to_s.split(":")
        normalized_parts = mac_parts.map {|s| Integer(s, 16).to_s(16) }
        normalized_parts.join(":")
    end
  end
end
