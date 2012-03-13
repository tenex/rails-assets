require "fileutils"

class Geminabox::DiskCache
  attr_reader :root_path

  def initialize(root_path)
    @root_path = root_path
    ensure_dir_exists!
  end

  def flush
    FileUtils.rm_rf(root_path)
    ensure_dir_exists!
  end

  def cache(key)
    key = Digest::MD5.hexdigest(key)
    read(key) || write(key, yield)
  end

  def read(key)
    path = File.join(root_path, key)
    File.read(path) if File.exists?(path)
  end

  def write(key, value)
    path = File.join(root_path, key)
    File.open(path, 'wb'){|f|
      f << value
    }
    value
  end

protected

  def ensure_dir_exists!
    FileUtils.mkdir_p(root_path)
  end
end
