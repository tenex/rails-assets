namespace :component do

  desc "Converts given bower component to Gem"
  task :convert, [:name, :version] => [:environment] do |t, args|
    # Remove component to force rebuild
    component, version = Component.get(args[:name], args[:version])
    version.update_attribute(:rebuild, true) if version.present?

    result = Build::Converter.run!(args[:name], args[:version]).inspect
    Build::Converter.index!(true)
    result
  end

  desc "Schedules update of all components"
  task :update_all => [:environment] do |t, args|
    UpdateScheduler.perform_async
  end

  desc "Schedules latest versions of given components to be converted"
  task :add, [:names] => [:environment] do |t, args|
    bower_names = args[:names].strip.split(':')

    STDOUT.print "Add #{bower_names.size} components? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      bower_names.each do |bower_name|
        BuildVersion.perform_async(bower_name, 'latest')
      end

      STDOUT.print "Done.\n"
    else
      STDOUT.print "No action has been performed.\n"
    end
  end

  desc "Removes given component from database and index"
  task :destroy, [:name, :version] => [:environment] do |t, args|
    component, version = Component.get(args[:name], args[:version])

    if args[:version] && version.present?
      puts "Removing #{version.gem_path}..."
      File.delete(version.gem_path) rescue nil
      version.destroy
      Build::Converter.index!(true)
    elsif args[:version].blank?
      component.versions.map(&:gem_path).each do |path|
        puts "Removing #{path}"
        File.delete(path) rescue nil
      end
      component.destroy
      Build::Converter.index!(true)
    end
  end

  desc "Removes all components from database and index"
  task :destroy_all => [:environment] do
    STDOUT.print "Are you sure? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      FileUtils.rm_rf(File.join(Figaro.env.data_dir, 'gems'))
      Component.delete_all
      Version.delete_all
      Build::Converter.index!(true)

      STDOUT.puts "All gems have been removed..."
    else
      STDOUT.puts "No action has been performed..."
    end
  end

  desc "Removes all .gem files with no matching db entry"
  task :clean_gems => [:environment] do
    to_remove = []

    Dir[File.join(Figaro.env.data_dir, 'gems', '*.gem')].each do |path|
      filename = File.basename(path).sub('.gem', '').sub(GEM_PREFIX, '')
      gem_name, gem_version = filename.split(/\-(?=\d)/)
      if component = Component.find_by(name: gem_name)
        version = component.versions.find_by(string: gem_version)

        if version.blank?
          to_remove << path
        end
      else
        to_remove << path
      end
    end

    next if to_remove.blank?

    STDOUT.puts "This will delete:"
    STDOUT.puts to_remove.map { |p| " * #{p}\n" }
    STDOUT.print "Are you sure? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      to_remove.each do |path|
        File.delete(path)
      end

      STDOUT.puts "#{to_remove.size} gems deleted from filesystem"
    end
  end

  desc "Removes all gemspecs without matching .gem file"
  task :clean_gemspecs => [:environment] do
    to_remove = []

    gems = Dir[File.join(
      Figaro.env.data_dir, 'gems', '*.gem'
    )].map { |s| s.split('/').last[0..-5] }

    gemspecs = Dir[File.join(
      Figaro.env.data_dir, 'quick', 'Marshal.4.8', '*.gemspec.rz'
    )].map { |s| s.split('/').last[0..-12] }

    (gemspecs - gems).each do |missing|
      to_remove << File.join(
        Figaro.env.data_dir, 'quick', 'Marshal.4.8',
        missing + '.gemspec.rz'
      )
    end

    next if to_remove.blank?

    STDOUT.puts "This will delete:"
    STDOUT.puts to_remove.map { |p| " * #{p}\n" }
    STDOUT.print "Are you sure? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      to_remove.each do |path|
        File.delete(path)
      end

      STDOUT.puts "#{to_remove.size} gemspecs deleted from filesystem"
    end
  end

  desc "Removes all db entries without matching .gem file"
  task :clean_db => [:environment] do
    to_remove = []

    gems = Dir[File.join(Figaro.env.data_dir, 'gems', '*.gem')]

    Version.includes(:component).find_each do |version|
      unless gems.include?(version.gem_path.to_s)
        to_remove << version
      end
    end

    next if to_remove.blank?

    STDOUT.puts "This will delete from database:"
    STDOUT.puts to_remove.map { |p| " * #{p.component.name}##{p.string}\n" }
    STDOUT.print "Are you sure? (y/n) "
    input = STDIN.gets.strip
    if input == 'y'
      to_remove.each do |version|
        version.destroy
      end

      STDOUT.puts "#{to_remove.size} versions destroyed"
    end
  end

  desc "Cleans .gem, .gemspec.rz, and database"
  task :clean_all => [:clean_gems, :clean_gemspecs, :clean_db]

  desc "Reindex"
  task :reindex => [:environment] do
    Version.all.load.each do |version|
      version.update_attributes(:rebuild => true)
      UpdateScheduler.perform_async
    end
  end

  desc "Updates version.bower_version field"
  task :update_bower_version => [:environment] do
    Component.all.load.each do |component|
      puts "Processing #{component.bower_name}..."

      versions = Build::Utils.bower('/tmp', 'info', component.bower_name)['versions'] || []

      versions.each do |version|
        if model = Version.find_by(string: Build::Utils.fix_version_string(version))
          model.update_attributes(:bower_version => version)
          puts "SUCCESS: updated #{component.bower_name}##{version}"
        else
          puts "WARNING: no matching version for #{component.bower_name}##{version}"
        end
      end
    end
  end
end
