desc "Convert bower package to gem. Run with rake convert[name] or convert[name#version]"
task :convert, [:pkg] => :environment do |t, args|
  name, version = args[:pkg].split("#", 2)

  Rails.logger.level = Logger::DEBUG
  if result = Build::Convert.new(name, version).convert!(debug: true, force: true)
    path = File.join(Build::FileStore.new.gems_root, result[:gem_component].filename)
    system "gem unpack #{path}"
  end
end

desc "List all gems"
task :list => :environment do
  Component.order("name ASC").each do |c|
    puts "#{c.name} (#{c.versions.pluck(:string).join(", ")})"
  end
end

desc "Remove gem"
task :remove, [:pkg] => :environment do |t, args|
  name, version = args[:pkg].split("#", 2)

  fs = Build::FileStore.new
  if component = Component.where(name: name).first
    (version ? [component.versions.where(string: version)] : component.versions).each do |v|
      Rails.logger.info "Removing #{v.gem.filename}"
      fs.delete(v.gem)
    end
    component.destroy
  else
    Rails.logger.error "Component #{name} not found"
  end

  Reindex.new.perform
end

desc "Update gem"
task :update, [:pkg] => :environment do |t, args|
  Update.new.perform(args[:pkg])
end

desc "Wipeout all data (data dir, redis index, installed gems)"
task :wipeout do
  print "Are you sure?"
  STDIN.gets

  system "rm -rf data"
  system "gem list rails-assets | xargs gem uninstall -ax"

  Version.delete_all
  Component.delete_all
end

desc "Rebuild all"
task :rebuild => :environment do
  Component.order("name ASC").each do |c|
    c.versions.each do |v|
      Build::Conver.new(c.name, v.string).convert!(debug: true, force: true)
    end
  end
end

desc "Reindex all gems"
task :reindex => :environment do
  Reindex.new.perform(:force)
end
