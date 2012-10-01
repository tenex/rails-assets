require "fileutils"

class Geminabox::DiskCache
  attr_reader :root_path

  def initialize(root_path)
    @root_path = root_path
    ensure_dir_exists!
  end

  def flush_key(key)
    path = path(key_hash(key))
    FileUtils.rm_f(path)
  end

  def flush
    FileUtils.rm_rf(root_path)
    ensure_dir_exists!
  end

  def cache(key)
    key_hash = key_hash(key)
    read(key_hash) || write(key_hash, yield)
  end

protected

  def ensure_dir_exists!
    FileUtils.mkdir_p(root_path)
  end

  def key_hash(key)
    Digest::MD5.hexdigest(key)
  end

  def path(key_hash)
    File.join(root_path, key_hash)
  end

  def read(key_hash)
    path = path(key_hash)
    File.read(path) if File.exists?(path)
  end

  def write(key_hash, value)
    path = path(key_hash)
    File.open(path, 'wb'){|f|
      f << value
    }
    value
  end

end
