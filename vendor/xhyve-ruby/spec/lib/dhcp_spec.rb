require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe Xhyve::DHCP do
  let(:leases) do
    {
      '9a:65:1b:12:cf:32' => '192.168.64.34',
      'a6:84:b2:34:cf:32' => '192.168.64.5',
      'ea:28:a:33:cf:32' => '192.168.64.4',
      'e2:ff:e:70:cf:32' => '192.168.64.3',
      '5a:90:52:13:cf:32' => '192.168.64.2'
    }
  end

  before :all do
    ENV['LEASES_FILE'] = File.join(FIXTURE_PATH, 'dhcpd_leases.txt')
    ENV['MAX_IP_WAIT'] = '1'
  end

  after :all do
    ENV.delete('LEASES_FILE')
    ENV.delete('MAX_IP_WAIT')
  end

  it 'parses the leases file to get an IP from a MAC' do
    leases.each do |mac, ip|
      expect(Xhyve::DHCP.get_ip_for_mac(mac)).to_not be_nil
      expect(Xhyve::DHCP.get_ip_for_mac(mac)).to eq(ip)
    end
  end

  it 'returns nil if no lease is found' do
    expect(Xhyve::DHCP.get_ip_for_mac('fakemac')).to be_nil
  end
end
