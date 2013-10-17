module Build
  class BowerComponent
    include Convert

    extend Utils

    MANIFESTS = ["component.json", "package.json", "bower.json"]

    attr_accessor :name, :version, :description,
                  :dependencies, :repository, :main,
                  :homepage, :user, :repo

    def initialize(name, version = nil)
      @name, @version = name, version

      if name.include?("/") # github repo
        @version ||= "master" # defaults to master
        @user, @name = name.split("/", 2)
      end

      # Validation
      raise BuildError.new("Empty bower component name") if @name.blank?
    end

    def github!(user)
      self.user = user

      self.repository = "git://github.com/#{user}/#{name}.git"
      self.homepage = "http://github.com/#{user}/#{name}"
    end

    def github?
      !!user
    end

    def full_name
      if github?
        "#{user}--#{name}"
      else
        name
      end
    end

    def github_name
      "#{user}/#{name}"
    end

    def full
      if github?
        "#{user}/#{name}##{version}"
      else
        version.blank? ? name : "#{name}##{version}"
      end
    end

    def gem
      @gem ||= GemComponent.new(self)
    end

    def self.from_bower(name, version = nil)
      full_name = version ?  name + "##{version}" : name
      json = Utils.bower('/tmp', "info #{full_name}")
      data = version ? json : json["latest"]

      self.new(name, data['version']).tap do |c|
        c.main = data['main'] ? [data['main']].flatten.compact : nil
        c.description = data['description'] || ""
        c.repository = "#{data['homepage']}.git"
        c.homepage = data['homepage']
        c.dependencies = data['dependencies'] || {}
      end
    end
  end
end
