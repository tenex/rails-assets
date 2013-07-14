module Rails
  module Assets
    module Utils
      def sh(cwd, *cmd)
        cmd = cmd.join(" ")
        log.debug "Running shell command '#{cmd}' in #{cwd}"

        status = Open3.popen3(cmd, :chdir => cwd) do |stdin, stdout, stderr, thr|
          stdout.each {|line| log.info("[stdout] " + line.chomp) }
          stderr.each {|line| log.warn("[stderr] " + line.chomp) }
          thr.value
        end

        unless status.success?
          log.error "Command '#{cmd}' failed with exit code #{status.to_i}"
          raise BuildError.new(cmd)
        end
      end

      def file_replace(file, &block)
        log.debug "Modifing file #{file}"
        content = File.read(file)
        content_was = content.dup

        proc = lambda do |source, target|
          content.gsub!(source, target)
        end

        block.call(proc)

        if content_was != content
          File.open(file, "w") do |f|
            f.write content
          end
          true
        else
          false
        end
      end

      def read_bower_file(path)
        log.info "Reading bower file #{path}"
        data = JSON.parse(File.read(path))
        dir = File.dirname(path)

        {
          :version => data["version"],
          :description => data["description"],
          :javascripts => Utils.select_javascripts(data["main"]),
          :dependencies => data["dependencies"],
          :repository => data["repository"]
        }.reject {|k,v| !v}
      end

      def self.select_javascripts(files)
        js = [files].flatten.select { |file| file.match(/\.js$/) }
        remove_min_js_duplicates(js)
      end

      def self.remove_min_js_duplicates(files)
        files.reject do |file|
          file.match(/min\.js$/) &&
            files.include?(file.gsub(".min", ""))
        end
      end
    end
  end
end
