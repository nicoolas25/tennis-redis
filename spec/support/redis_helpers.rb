require "redis"

module RedisHelpers
  def redis
    @redis ||= ::Redis.new
  end

  def remove_keys(template)
    keys = redis.keys(template)
    redis.del(*keys) if keys.any?
  end
end
