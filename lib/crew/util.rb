require 'shellwords'

module Crew
  class AssertionError < RuntimeError
  end

  module Util
    def assert(value, message = nil)
      value or begin
        message ||= "expected #{value.inspect} to be true at #{caller.first}"
        raise AssertionError, message
      end
    end

    def retryable(opts = {})
      intervals = 10.times.map { 0.1 }.to_a
      timeout = opts[:timeout]
      max = opts[:max] || 1.0
      out = nil
      begin
        Timeout::timeout(max) do
          begin
            Timeout::timeout(timeout) { out = yield }
          end
        end
      rescue
        if intervals.empty?
          raise
        else
          sleep intervals.shift
          retry
        end
      end
      out
    end

    def logger
      @home ? @home.logger : @logger
    end

    def poll(name, opts = {})
      interval = opts[:interval] || 1
      timeout = opts[:timeout]
      spinner = logger.spinner(name)
      val = nil
      begin
        logger.muted do
          Timeout::timeout(timeout) do
            begin
              val = yield
            rescue
              spinner[false]
              sleep interval
              retry
            else
              spinner[true]
            end
          end
        end
      rescue Timeout::Error
        assert false, "timeout of #{timeout} exceeded"
      end
      val
    end

    def escape(*words)
      Shellwords.shelljoin(words)
    end
  end
end
