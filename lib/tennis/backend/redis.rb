require "tennis"
require "tennis/backend/abstract"
require "tennis/backend/serializer"
require "tennis/backend/task"

require "redis"
require "redis/namespace"

module Tennis
  module Backend
    class Redis < Abstract
      def initialize(logger:, url:, namespace: "tennis")
        super(logger: logger)
        @redis_url = url
        @redis_namespace = namespace
      end

      # Delayed jobs are not yet supported with Redis backend
      def enqueue(job:, method:, args:, delay: nil)
        serialized_task = serialize_task(job, method, args)
        client.lpush(queue_name(job.class), serialized_task)
      end

      def receive(job_classes:, timeout: 1.0)
        queues_cmd = queues(job_classes).keys.shuffle
        queues_cmd << timeout.to_i if timeout
        queue_name, serialized_task = client.brpop(*queues_cmd)
        return nil unless queue_name
        deserialize_task(serialized_task)
      end

      def ack(task)
      end

      def requeue(task)
      end

      private

      def client
        @client ||= begin
          redis = ::Redis.new(url: @redis_url)
          ::Redis::Namespace.new(@redis_namespace, redis: redis)
        end
      end

      def queue_name(job_class)
        @queue_names ||= {}
        @queue_names[job_class] ||= job_class.name.gsub("::", "-").downcase
      end

      def queues(job_classes)
        @queues ||= {}
        @queues[job_classes] ||= job_classes.each_with_object({}) do |klass, hash|
          hash[queue_name(klass)] = klass
        end
      end

      def serialize_task(job, method, args)
        Serializer.new.dump([job, method, args])
      end

      def deserialize_task(serialized_task)
        job, method, args = Serializer.new.load(serialized_task)
        Task.new(self, nil, job, method, args)
      end

    end
  end
end
