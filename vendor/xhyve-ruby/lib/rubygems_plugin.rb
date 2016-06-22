Gem.post_install do
  if Gem::Platform.local.os =~ /darwin/
    # Required until https://github.com/mist64/xhyve/issues/60 is resolved
    bin = File.expand_path('../xhyve/vendor/xhyve', __FILE__)
    `/usr/bin/osascript -e 'do shell script "chown root #{bin} && chmod +s #{bin}" with administrator privileges'`
  end
end
