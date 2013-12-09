namespace :component do

  desc "Converts given bower component to Gem"
  task :convert, [:name, :version] => [:environment] do |t, args|
    # Remove component to force rebuild
    component, version = Component.get(args[:name], args[:version])
    version.destroy if version.present?

    puts Build::Converter.run!(args[:name], args[:version]).inspect
  end

  desc "Removes given component from database and index"
  task :destroy, [:name, :version] => [:environment] do |t, args|
    component, version = Component.get(args[:name], args[:version])

    if args[:version] && version.present?
      puts "Removing #{version.gem_path}..."
      File.delete(version.gem_path) rescue nil
      version.destroy
      Reindex.new.perform
    elsif args[:version].blank?
      component.versions.map(&:gem_path).each do |path|
        puts "Removing #{path}"
        File.delete(path) rescue nil
      end
      component.destroy
      Reindex.new.perform
    end
  end

  desc "Removes all components from database and index"
  task :destroy_all => [:environment] do
    STDOUT.print "Are you sure? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      FileUtils.rm_rf(Rails.root.join('public', 'gems'))
      Component.destroy_all
      Reindex.new.perform

      STDOUT.puts "All gems have been removed..."
    else
      STDOUT.puts "No action has been performed..."
    end
  end

  desc "Reindex"
  task :reindex => [:environment] do
    Version.all.load.each do |version|
      version.update_attributes(
        :build_status => nil, :build_message => nil,
        :asset_paths => [], :main_paths => []
      )

      UpdateScheduler.perform_async
    end
  end
end
