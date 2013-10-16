require "open3"

module Build
  module Utils

    def sh(cwd, *cmd)
      cmd = cmd.join(" ")

      Rails.logger.debug "cd #{cwd} && #{cmd}"

      status, output, error =
        Open3.popen3(cmd, :chdir => cwd) do |stdin, stdout, stderr, thr|
          [thr.value, stdout.read, stderr.read]
        end

      Rails.logger.info("#{cmd}\n#{output}") if output.present?
      Rails.logger.warn("#{cmd}\n#{error}") if error.present?

      if status.success?
        output
      else
        raise BuildError.new(
          "Command '#{cmd}' failed with exit code #{status.to_i}",
          :log => output + error
        )
      end
    end

    def fix_version_string(version)
      version = version.to_s

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

      if version.strip == "latest" || version.strip == "master"
        nil
      elsif version.match(/^[^\/]+\/[^\/]+$/) 
        nil
      elsif version.match(/^(http|git|ssh)/)
        if version.split('/').last =~ /^v?([\w\.-]+)$/
          fix_version_string($1.strip)
        else
          nil
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
      version = version.to_s

      if version.match(/^[^\/]+\/[^\/]+$/) 
        version.sub('/', '--')
      elsif version =~ /github\.com\/([^\/]+\/[^\/]+)/
        $1
      else
        gem_name
      end
    end
  end
end
