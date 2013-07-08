require "sinatra/base"
require "slim"


require "rails/assets/config"
require "rails/assets/component"
require "rails/assets/index"
# require "rails/assets/incoming_gem"
require "rails/assets/convert"
require "rails/assets/serve"


# require 'rubygems'
# require 'digest/md5'
# require 'builder'
# require 'rubygems/indexer'
# require 'rubygems/package'
# require 'hostess'
# require 'rss/atom'
# require 'tempfile'
# require 'slim'
# require 'json'
# require 'redcarpet'



module Rails
  module Assets
    class Web < Sinatra::Base
      set :views, File.join(File.dirname(__FILE__), *%w[.. .. .. views])
      set :public_folder, File.join(File.dirname(__FILE__), *%w[.. .. .. public])

      use Serve

      get '/' do
        "Comming soon..."
      end

      get '/home' do
        slim :index
      end

      def index
        @index ||= Index.new
      end

      def json(*args)
        status, data = args.size > 1 ? [args.first, args.last] : [200, args.first]

        content_type :json
        resp = JSON.dump(data)
        if status >= 400
          halt status, resp
        else
          resp
        end
      end

      post '/convert.json' do
        ps = params.empty? ? JSON.parse(request.body.read) : params
        component = Component.new(ps["pkg"].to_s.strip)

        io = STDOUT #StringIO.new


        if index.exists?(component)
          halt 302
        else
          if Convert.new(component).convert!(:io => STDOUT)
            json 201, :gem => component.gem_name, :version => component.version
          else
            halt 422
          end
        end
      end

      get "/api/v1/dependencies" do
        gems = params["gems"].to_s
          .split(",")
          .select {|e| e.start_with?(GEM_PREFIX) }
          .flat_map do |name|
          vs = index.versions(name)

          if vs.empty?
            component = Component.new(name)
            if Convert.new(component).convert!
              vs = index.versions(name)
            end
          end

          vs.map do |v|
            {
              :name => name,
              :platform => "ruby",
              :number => v,
              :dependencies => index.dependencies(name, v).to_a
            }
          end
        end

        # json gems
        Marshal.dump(gems)
      end


          # Bower::Convert.new(pkg).build!(io) do |tmpfile|
          #   gem = IncomingGem.new(File.open(tmpfile))

          #   # prepare_data_folders
          #   # error_response(400, "Cannot process gem") unless gem.valid?
          #   # # handle_replacement(gem) unless params[:overwrite] == "true"
          #   # write_and_index(gem)
          # end

        # end

        # begin


        #   # reindex(:force_rebuild)
        #   # @loaded_gems = nil

        #   # puts io.string
        #   json :gem => "rails-assets-#{name}"
        # rescue Bower::BuildError, Exception => ex
        #   io.puts ex.message
        #   io.puts ex.backtrace.take(5).first.gsub(File.dirname(File.dirname(__FILE__)), "")
        #   json({:error => ex.message, :log => io.string}, 422)
        # end

    end
  end
end

# module Rails
#   class Assets < Sinatra::Base
#     enable :static, :methodoverride

#     set :data, ENV["DATA_DIR"] || File.join(File.dirname(__FILE__), *%w[.. .. data])
#     set :build_legacy, false
#     set :incremental_updates, true
#     set :allow_replace, false
#     set :gem_permissions, 0644
#     set :allow_delete, true
#     use Hostess

#     class << self
#       def disallow_replace?
#         ! allow_replace
#       end

#       def allow_delete?
#         allow_delete
#       end

#       def fixup_bundler_rubygems!
#         return if @post_reset_hook_applied
#         Gem.post_reset{ Gem::Specification.all = nil } if defined? Bundler and Gem.respond_to? :post_reset
#         @post_reset_hook_applied = true
#       end
#     end

#     autoload :GemVersionCollection, "rails/assets/gem_version_collection"
#     autoload :GemVersion, "rails/assets/gem_version"
#     autoload :DiskCache, "rails/assets/disk_cache"
#     autoload :IncomingGem, "rails/assets/incoming_gem"
#     autoload :Bower, "bower/build"


#     get '/index.json' do
#       gems = load_gems.by_name.select {|n,_| n =~ /^rails-assets-/ }.map do |name, versions|
#         data = {
#           :name => name.gsub(/^rails-assets-/, ""),
#           :versions => versions.sort.map {|e| e.number }.reverse
#         }

#         if spec = spec_for(name, versions.newest.number)
#           data[:description] = Tilt[:markdown].new { spec.description }.render
#           data[:homepage] = spec.homepage

#           data[:dependencies] = spec.runtime_dependencies.map do |dep|
#             {
#               :name => dep.name.gsub(/^rails-assets-/, ""),
#               :reqs => dep.requirements_list
#             }
#           end
#         end

#         data
#       end

#       json gems
#     end

#     get '/atom.xml' do
#       @gems = load_gems
#       erb :atom, :layout => false
#     end

#     get '/api/v1/dependencies' do
#       query_gems = params[:gems].to_s.split(',')
#       deps = query_gems.inject([]){|memo, query_gem| memo + gem_dependencies(query_gem) }
#       Marshal.dump(deps)
#     end

#     get '/upload' do
#       erb :upload
#     end

#     get '/reindex' do
#       reindex(:force_rebuild)
#       redirect url("/")
#     end

#     get '/gems/:gemname' do
#       gems = Hash[load_gems.by_name]
#       @gem = gems[params[:gemname]]
#       halt 404 unless @gem
#       erb :gem
#     end

#     delete '/gems/*.gem' do
#       unless Rails::Assets.allow_delete?
#         error_response(403, 'Gem deletion is disabled - see https://github.com/cwninja/rails-assets/issues/115')
#       end

#       if File.exists? file_path
#         File.delete file_path
#         reindex(:force_rebuild)
#         "OK"
#       else
#         halt 404
#       end
#     end


#     # post '/upload' do
#     #   unless params[:file] && params[:file][:filename] && (tmpfile = params[:file][:tempfile])
#     #     @error = "No file selected"
#     #     halt [400, erb(:upload)]
#     #   end
#     #   handle_incoming_gem(IncomingGem.new(tmpfile))
#     # end

#     # post '/api/v1/gems' do
#     #   begin
#     #     handle_incoming_gem(IncomingGem.new(request.body))
#     #   rescue Object => o
#     #     File.open "/tmp/debug.txt", "a" do |io|
#     #       io.puts o, o.backtrace
#     #     end
#     #   end
#     # end

#   private

#     def json(data, status = 200)
#       content_type :json
#       resp = JSON.dump(data)
#       if status >= 400
#         halt status, resp
#       else
#         resp
#       end
#     end

#     def handle_incoming_gem(gem)
#       prepare_data_folders
#       error_response(400, "Cannot process gem") unless gem.valid?
#       handle_replacement(gem) unless params[:overwrite] == "true"
#       write_and_index(gem)

#       if api_request?
#         "Gem #{gem.name} received and indexed."
#       else
#         redirect url("/")
#       end
#     end

#     def api_request?
#       request.accept.first != "text/html"
#     end

#     def error_response(code, message)
#       halt [code, message] if api_request?
#       html = <<HTML
# <html>
#   <head><title>Error - #{code}</title></head>
#   <body>
#     <h1>Error - #{code}</h1>
#     <p>#{message}</p>
#   </body>
# </html>
# HTML
#       halt [code, html]
#     end



#     def handle_replacement(gem)
#       if Rails::Assets.disallow_replace? and File.exist?(gem.dest_filename)
#         existing_file_digest = Digest::SHA1.file(gem.dest_filename).hexdigest

#         if existing_file_digest != gem.hexdigest
#           error_response(409, "Updating an existing gem is not permitted.\nYou should either delete the existing version, or change your version number.")
#         else
#           error_response(200, "Ignoring upload, you uploaded the same thing previously.\nPlease use -o to ovewrite.")
#         end
#       end
#     end

#     def write_and_index(gem)
#       tmpfile = gem.gem_data
#       atomic_write(gem.dest_filename) do |f|
#         while blk = tmpfile.read(65536)
#           f << blk
#         end
#       end
#       reindex
#     end

#     def reindex(force_rebuild = false)
#       Rails::Assets.fixup_bundler_rubygems!
#       force_rebuild = true unless settings.incremental_updates
#       if force_rebuild
#         indexer.generate_index
#         dependency_cache.flush
#       else
#         begin
#           require 'rails/assets/indexer'
#           updated_gemspecs = Rails::Assets::Indexer.updated_gemspecs(indexer)
#           Rails::Assets::Indexer.patch_rubygems_update_index_pre_1_8_25(indexer)
#           indexer.update_index
#           updated_gemspecs.each { |gem| dependency_cache.flush_key(gem.name) }
#         rescue => e
#           puts "#{e.class}:#{e.message}"
#           puts e.backtrace.join("\n")
#           reindex(:force_rebuild)
#         end
#       end
#     end

#     def indexer
#       Gem::Indexer.new(settings.data, :build_legacy => settings.build_legacy)
#     end

#     def file_path
#       File.expand_path(File.join(settings.data, *request.path_info))
#     end

#     def dependency_cache
#       @dependency_cache ||= Rails::Assets::DiskCache.new(File.join(settings.data, "_cache"))
#     end

#     def all_gems
#       %w(specs prerelease_specs).map{ |specs_file_type|
#         specs_file_path = File.join(settings.data, "#{specs_file_type}.#{Gem.marshal_version}.gz")
#         if File.exists?(specs_file_path)
#           Marshal.load(Gem.gunzip(Gem.read_binary(specs_file_path)))
#         else
#           []
#         end
#       }.inject(:|)
#     end

#     def load_gems
#       @loaded_gems ||= Rails::Assets::GemVersionCollection.new(all_gems)
#     end

#     def index_gems(gems)
#       Set.new(gems.map{|gem| gem.name[0..0].downcase})
#     end

#     # based on http://as.rubyonrails.org/classes/File.html
#     def atomic_write(file_name)
#       temp_dir = File.join(settings.data, "_temp")
#       FileUtils.mkdir_p(temp_dir)
#       temp_file = Tempfile.new("." + File.basename(file_name), temp_dir)
#       yield temp_file
#       temp_file.close
#       File.rename(temp_file.path, file_name)
#       File.chmod(settings.gem_permissions, file_name)
#     end

#     helpers do
#       def spec_for(gem_name, version)
#         spec_file = File.join(settings.data, "quick", "Marshal.#{Gem.marshal_version}", "#{gem_name}-#{version}.gemspec.rz")
#         Marshal.load(Gem.inflate(File.read(spec_file))) if File.exists? spec_file
#       end

#       def display_dependencies(deps)
#         deps.map do |dep|
#           <<-EOS
#             <span class="name">#{dep.name.gsub(/^rails-assets-/, "")}</span>
#             <span class="req"> (#{dep.requirements_list.join(", ")})</span>
#           EOS
#         end.join(", ")
#       end

#       # Return a list of versions of gem 'gem_name' with the dependencies of each version.
#       def gem_dependencies(gem_name)
#         build_gem(gem_name)
#         dependency_cache.marshal_cache(gem_name) do
#           load_gems.
#             select { |gem| gem_name == gem.name }.
#             map    { |gem| [gem, spec_for(gem.name, gem.number)] }.
#             reject { |(_, spec)| spec.nil? }.
#             map do |(gem, spec)|
#               {
#                 :name => gem.name,
#                 :number => gem.number.version,
#                 :platform => gem.platform,
#                 :dependencies => runtime_dependencies(spec)
#               }
#             end
#         end
#       end

#       def runtime_dependencies(spec)
#         spec.
#           dependencies.
#           select { |dep| dep.type == :runtime }.
#           map    { |dep| [dep.name, dep.requirement.to_s] }
#       end

#       def build_gem(gem_name)
#         if gem_name =~ /^rails-assets-/ && !load_gems.find {|e| e.name == gem_name }
#           Bower::Convert.new(gem_name.gsub(/^rails-assets-/, '')).build! do |tmpfile|
#             gem = IncomingGem.new(File.open(tmpfile))

#             prepare_data_folders
#             error_response(400, "Cannot process gem") unless gem.valid?
#             # handle_replacement(gem) unless params[:overwrite] == "true"
#             write_and_index(gem)
#           end
#           reindex(:force_rebuild)
#           @loaded_gems = nil
#         end
#       end
#     end
#   end
# end
