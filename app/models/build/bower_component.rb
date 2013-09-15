module Build
  class BowerComponent
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
      self.homepage = self.class.get_homepage_from_repository(repository)
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

    class << self
      def from_manifests(dir, name)
        data = MANIFESTS
                .map {|m| File.join(dir, m) }
                .select {|f| File.exists?(f) }
                .map {|f| read_manifest(f) }
                .inject({}){|h,e| h.merge(e) }

        self.new(name, data[:version]).tap do |c|
          c.description   = data[:description]
          c.dependencies  = (data[:dependencies] || {})
          c.main          = data[:main]
          c.repository    = data[:repository]
          c.homepage      = data[:homepage]
          c.homepage      = get_homepage_from_repository(data[:repository]) if c.homepage.blank?
        end
      end

      def get_homepage_from_repository(repo)
        case repo.to_s
        when %r|//github.com/(.+)/(.+?)(\.git)?$|
            "http://github.com/#{$1}/#{$2}"
        end
      end

      def read_manifest(path)
        Rails.logger.info "Reading manifest file #{path}"
        data = JSON.parse(File.read(path))

        {
          version:      data["version"],
          description:  data["description"],
          main:         [data["main"]].flatten.reject {|e| e.nil?},
          dependencies: data["dependencies"],
          repository:   data["repository"].is_a?(Hash) ? data["repository"]["url"] : data["repository"],
          homepage:     data["homepage"]
        }.reject {|k,v| v.blank? }
      end
    end
  end
end
