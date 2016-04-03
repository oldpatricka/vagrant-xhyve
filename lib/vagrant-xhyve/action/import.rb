require "log4r"
require "json"
require "fileutils"

module VagrantPlugins
  module XHYVE
    module Action
      # This terminates the running instance.
      class Import
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_xhyve::action::import")
        end

        def call(env)

          #TODO: Progress bar
          env[:ui].info("Importing box...")
          # something like:
          # # tempfile is a File instance
          # File.open( new_file, 'wb' ) do |f|
          #   # Read in small 65k chunks to limit memory usage
          #     f.write(tempfile.read(2**16)) until tempfile.eof?
          #     end

          image_dir = File.join(env[:machine].data_dir, "image")
          box_dir = env[:machine].box.directory

          box_files = [File.join(box_dir, "vmlinuz"), File.join(box_dir, "initrd.gz")]

          0.upto(10).each do |blockidx|
            block_file = File.join(box_dir, "block#{blockidx}.img")
            if (File.exist? block_file) then
              box_files.pust(block_file)
            else
              break
            end
          end

          # TODO: delete before release
          hdd_file = File.join(box_dir, "hdd.img")
          if (File.exist? hdd_file) then
            box_files.push(hdd_file)
          end

          FileUtils.mkdir_p(image_dir)
          FileUtils.cp(box_files, image_dir)

          env[:ui].info("Done importing box.")

          @app.call(env)
        end

        def process_alive(pid)
          begin
            Process.getpgid(pid)
            true
          rescue Errno::ESRCH
            false
          end
        end
      end
    end
  end
end
