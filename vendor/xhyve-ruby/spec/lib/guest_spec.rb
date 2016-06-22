require File.expand_path('../../spec_helper.rb', __FILE__)

RSpec.describe Xhyve::Guest do
  before :all do
    kernel = File.join(FIXTURE_PATH, 'guest', 'vmlinuz')
    initrd = File.join(FIXTURE_PATH, 'guest', 'initrd')
    blockdev = File.join(FIXTURE_PATH, 'guest', 'loop.img')
    cmdline = 'earlyprintk=true console=ttyS0 user=console opt=vda tce=vda'
    uuid =   SecureRandom.uuid  # '32e54269-d1e2-4bdf-b4ff-bbe0eb42572d' #

    @guest = Xhyve::Guest.new(kernel: kernel, initrd: initrd, cmdline: cmdline, blockdevs: blockdev, uuid: uuid, serial: 'com1')
    @guest.start
  end

  after :all do
    @guest.stop
  end

  it 'Can start a guest' do
    expect(@guest.pid).to_not be_nil
    expect(@guest.pid).to be > 0
    expect(@guest.running?).to eq(true)
  end

  it 'Can get the MAC of a guest' do
    expect(@guest.mac).to_not be_nil
    expect(@guest.mac).to_not be_empty
    expect(@guest.mac).to match(/\w\w:\w\w:\w\w:\w\w:\w\w:\w\w/)
  end

  it 'Can get the IP of a guest' do
    expect(@guest.ip).to_not be_nil
    expect(@guest.ip).to match(/\d+\.+\d+\.\d+\.\d+/)
  end

  it 'Can ping the guest' do
    expect(ping(@guest.ip)).to eq(true)
  end

  it 'Can ssh to the guest' do
    expect(on_guest(@guest.ip, 'hostname')).to eq('box')
  end

  it 'Correctly sets processors' do
    expect(on_guest(@guest.ip, "cat /proc/cpuinfo | grep 'cpu cores' | awk '{print $4}'")).to eq('1')
  end

  it 'Correctly sets memory' do
    expect(on_guest(@guest.ip, "free -mm | grep 'Mem:' | awk '{print $2}'").to_i).to be_within(50).of(500)
  end
end unless ENV['TRAVIS']
