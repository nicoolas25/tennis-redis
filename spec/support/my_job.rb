require "tennis"

class MyJob
  include Tennis::Job

  def sum(*args)
    args.inject(&:+)
  end

  def job_dump
    nil
  end

  def self.job_load(_)
    new
  end
end
