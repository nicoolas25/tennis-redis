require "securerandom"

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
        meta = { "enqueued_at" => Time.now.to_i }
        task = Task.new(self, generate_task_id, job, method, args, meta)
        client_push(task)
      end

      def receive(job_classes:, timeout: 1.0)
        queues_cmd = queues(job_classes).keys.shuffle
        queues_cmd << timeout.to_i if timeout
        queue_name, serialized_task = client.brpop(*queues_cmd)
        return nil unless queue_name
        deserialize_task(serialized_task)
      end

      def ack(task)
        # Nothing to do here
      end

      def requeue(task)
        (task.meta["requeued_at"] ||= []) << Time.now.to_i
        client_push(task)
      end

      private

      def client
        @client ||= begin
          redis = ::Redis.new(url: @redis_url)
          ::Redis::Namespace.new(@redis_namespace, redis: redis)
        end
      end

      def client_push(task)
        serialized_task = serialize(task)
        client.lpush(queue_name(task.job.class), serialized_task)
      end

      def serialize(task)
        Serializer.new.dump({
          "id"     => task.task_id,
          "job"    => task.job,
          "method" => task.method,
          "args"   => task.args,
          "meta"   => task.meta,
        })
      end

      def deserialize_task(serialized_task)
        hash = Serializer.new.load(serialized_task)
        Task.new(self, hash["id"], hash["job"], hash["method"], hash["args"], hash["meta"])
      end

      def generate_task_id
        SecureRandom.hex(10)
      end

      def queues(job_classes)
        @queues ||= {}
        @queues[job_classes] ||= job_classes.map { |klass| queue_name(klass) }
      end

      def queue_name(job_class)
        @queue_names ||= {}
        @queue_names[job_class] ||= job_class.name.gsub("::", "-").downcase
      end

    end
  end
end
