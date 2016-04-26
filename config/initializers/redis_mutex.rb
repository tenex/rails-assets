Redis::Classy.db = Redis.new(
  url: ENV['REDIS_URL'], namespace: REDIS_NAMESPACE
)
