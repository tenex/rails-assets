require "open3"

module Build
  module Utils extend self

    # Returns The Hash result if command succeeded.
    # Raises The BowerError if command failed.
    def bower(path, *command)
      command = "#{BOWER_BIN} #{command.join(' ')} --json --quiet"
      command += " --config.tmp=#{Figaro.env.bower_tmp}" if Figaro.env.bower_tmp.present?
      command += " --config.storage.packages=#{Figaro.env.bower_cache}" if Figaro.env.bower_cache.present?
      JSON.parse(Utils.sh(path, command))
    rescue ShellError => e
      raise BowerError.from_shell_error(e)
    end

    # Returns The String stdout if command succeeded.
    # Raises The ShellError if command failed.
    def sh(cwd, *cmd)
      cmd = cmd.join(" ")

      Rails.logger.debug "cd #{cwd} && #{cmd}"

      output, error, status =
        Open3.popen3(cmd, :chdir => cwd) do |stdin, stdout, stderr, thr|
          [stdout.read, stderr.read, thr.value]
        end

      Rails.logger.debug("#{cmd}\n#{output}") if output.present?
      Rails.logger.warn("#{cmd}\n#{error}") if error.present? && !status.success?

      raise ShellError.new(error, cwd, cmd) unless status.success?

      output
    end

    def fix_version_string(version)
      version = version.to_s.dup

      if version.include?('||')
        raise BuildError.new(
          "Rubygems does not support || in version string '#{version}'"
        )
      end

      # Remove any unnecessary spaces
      version = version.split(' ').join(' ')

      specifiers = ['>', '<', '>=', '<=', '~', '~>', '=', '!=']

      specifiers.each do |specifier|
        version = version.gsub(/#{specifier}\s/) { specifier }
      end

      if version.include?(' ')
        return version.split(' ').map do |v|
          Utils.fix_version_string(v)
        end.join(', ')
      end

      if version.include?('#')
        return Utils.fix_version_string(version.split('#').last)
      end

      version = version[1..-1] if version[0] == 'v'

      version = version.gsub('.*', '.x')

      version = if ['latest', 'master', '*'].include?(version)
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

          unless version.include?('>')
            version = "~> #{version.gsub('~', '')}"
          end
        end

        version.gsub!(/[+-]/, '.')

        version.gsub!(/~(?!>)\s?(\d)/, '~> \1')

        version = version[1..-1].strip if version[0] == '='

        version
      end

      specifiers.each do |specifier|
        version = version.gsub(/#{specifier}(\d)/) { specifier + ' ' + $1 }
      end

      version
    end

    # TODO: cleanup
    def fix_gem_name(gem_name, version)
      version = version.to_s.gsub(/#.*$/, '')
      version = version.gsub(/\.git$/, '')

      gem_name = if version.match(/^[^\/]+\/[^\/]+$/)
        version
      elsif version =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1
      else
        gem_name.sub(/^#{Regexp.escape(GEM_PREFIX)}/, '')
      end

      gem_name = gem_name.to_s.gsub(/#.*$/, '')
      gem_name = gem_name.gsub(/\.git$/, '')

      gem_name = if gem_name.match(/^[^\/]+\/[^\/]+$/)
        gem_name
      elsif gem_name =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1
      else
        gem_name.sub(/^#{Regexp.escape(GEM_PREFIX)}/, '')
      end

      gem_name.sub('/', '--')
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
