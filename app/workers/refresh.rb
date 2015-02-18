require 'net/http'

module Net
  class HTTP::Purge < HTTPRequest
    METHOD='PURGE'
    REQUEST_HAS_BODY = false
    RESPONSE_HAS_BODY = true
  end
end

class Refresh
  include Sidekiq::Worker

  sidekiq_options queue: 'refresh', unique: :all, retry: 3

  def perform(version_id)
    version = Version.find(version_id)

    purge(version.gem_url)
    purge(version.gemspec_url)

    true
  end

  def purge(url)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    http.start do |http|
      req = Net::HTTP::Purge.new(uri.request_uri)
      req['X-Shelly-Cache-Auth'] = ENV['SHELLY_CACHE_AUTH']
      resp = http.request(req)
      unless (200...400).include?(resp.code.to_i)
        raise resp.body
      end
    end
  end
end
