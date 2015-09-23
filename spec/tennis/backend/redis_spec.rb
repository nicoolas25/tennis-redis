require "tennis/backend/redis"

require "support/redis_helpers"
require "support/my_job"

RSpec.describe Tennis::Backend::Redis do
  include RedisHelpers

  before { remove_keys "tennis-test:queue:*" }

  describe "#enqueue" do
    subject(:enqueue) { instance.enqueue(job: job, method: method, args: args) }

    it "creates a key 'tennis-test:queue:myjob' into redis" do
      enqueue
      expect(redis.keys).to include "tennis-test:queue:myjob"
    end

    it "adds the task into the Redis list" do
      expect {
        enqueue
      }.to change {
        redis.rpop("tennis-test:queue:myjob")
      }.from(nil)
    end
  end

  describe "#receive" do
    subject(:receive) { instance.receive(job_classes: [MyJob], timeout: timeout) }

    context "when no job are available" do
      it { is_expected.to be_nil }
    end

    context "when a job had been enqueued" do
      # Enqueue a job
      before { instance.enqueue(job: job, method: method, args: args) }

      it { is_expected.to be_a Tennis::Backend::Task }

      context "with a bigger timeout" do
        let(:timeout) { 100.0 }

        it "returns the task instantly" do
          expect(receive).to be_a Tennis::Backend::Task
        end
      end

      describe "the returned task" do
        subject(:task) { receive }

        it "matches the given job, method and arguments" do
          expect(task.job).to be_a MyJob
          expect(task.method).to eq "sum"
          expect(task.args).to eq [1, 2, 3]
        end

        it "adds meta informations: 'enqueued_at'" do
          expect(task.meta).to include "enqueued_at"
        end
      end
    end
  end

  describe "#requeue" do
    subject(:requeue) { instance.requeue(task) }

    before do
      # Enqueue a job and retrieve the associated task
      instance.enqueue(job: job, method: method, args: args)
      task
    end

    it "adds back the task into the Redis list" do
      expect {
        requeue
      }.to change {
        redis.rpop("tennis-test:queue:myjob")
      }.from(nil)
    end

    describe "the task after being requeued" do
      subject(:requeued_task) { instance.receive(job_classes: [MyJob]) }

      # Requeue the task
      before { requeue }

      it "adds meta information: 'requeued_at'" do
        expect(requeued_task.meta).to include "requeued_at"
        expect(requeued_task.meta["requeued_at"]).to be_an Array
        expect(requeued_task.meta["requeued_at"].size).to eq 1
      end
    end

    let(:task) { instance.receive(job_classes: [MyJob]) }
  end

  let(:job) { MyJob.new }
  let(:method) { "sum" }
  let(:args) { [1, 2, 3] }
  let(:timeout) { 0.0 }
  let(:instance) do
    described_class.new(logger: nil, url: "redis://localhost:6379", namespace: "tennis-test")
  end

end
