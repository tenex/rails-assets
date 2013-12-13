require "open3"

module Build
  module Utils extend self

    # Returns The Hash result if command succeeded.
    # Raises The BowerError if command failed.
    def bower(path, *command)
      command = "#{BOWER_BIN} #{command.join(' ')} --json --quiet"
      JSON.parse(Utils.sh(path, command))
    rescue ShellError => e
      raise BowerError.from_shell_error(e)
    end

    # Returns The String stdout if command succeeded.
    # Raises The ShellError if command failed.
    def sh(cwd, *cmd)
      cmd = cmd.join(" ")

      Rails.logger.debug "cd #{cwd} && #{cmd}"

      status, output, error =
        Open3.popen3(cmd, :chdir => cwd) do |stdin, stdout, stderr, thr|
          [thr.value, stdout.read, stderr.read]
        end

      Rails.logger.debug("#{cmd}\n#{output}") if output.present?
      Rails.logger.warn("#{cmd}\n#{error}") if error.present? && !status.success?

      raise ShellError.new(error, cwd, cmd) unless status.success?
      
      output
    end

    def fix_version_string(version)
      version = version.dup.to_s

      if version =~ /^v(.+)/
        version = $1.strip
      end

      if version =~ />=(.+)<(.+)/
        if $1.strip[0] != $2.strip[0]
          version = "~> #{$1.strip.match(/\d+\.\d+/)}"
        else
          version = "~> #{$1.strip}"
        end
      end

      if version =~ />=(.+)/
        version = ">= #{$1.strip}"
      end

      if ['latest', 'master', '*'].include?(version.strip)
        ">= 0"
      elsif version.match(/^[^\/]+\/[^\/]+$/) 
        ">= 0"
      elsif version.match(/^(http|git|ssh)/)
        if version.split('/').last =~ /^v?([\w\.-]+)$/
          fix_version_string($1.strip)
        else
          ">= 0"
        end
      else
        if version.match('.x')
          version.gsub!('.x', '.0')
          version = "~> #{version.gsub('~', '')}"
        end

        version.gsub!('-', '.')
        version.gsub!(/~(?!>)\s?(\d)/, '~> \1')

        version
      end
    end

    def fix_gem_name(gem_name, version)
      
      version = version.to_s.gsub(/#.*$/, '')
      version = version.gsub(/\.git$/, '')

      if version.match(/^[^\/]+\/[^\/]+$/) 
        version.sub('/', '--')
      elsif version =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1.sub('/', '--')
      else
        gem_name.sub(/^#{Regexp.escape(GEM_PREFIX)}/, '')
      end
    end

    # TODO: tests
    def fix_dependencies(dependencies)
      Hash[dependencies.map do |name, version|
        [
          "#{GEM_PREFIX}#{Utils.fix_gem_name(name, version)}",
          Utils.fix_version_string(version)
        ]
      end]
    end
  end
end
