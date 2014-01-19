module Crew
  class Task
    class Test

      include Util

      class FailedException < RuntimeError
      end

      class Result < Struct.new(:context_name, :task_name, :index, :status, :extras)
        def missing?
          status == 'missing'
        end

        def passed?
          status == 'pass'
        end

        def failed?
          status == 'fail'
        end

        def skipped?
          status == 'skip'
        end

        def to_s
          out = "#{task_name}##{index} (#{context_name}) = #{status}"
          if extras['start_time'] && extras['end_time']
            out << "\nRan in #{extras['end_time'] - extras['start_time']}"
          end
          if extras['exception']
            e = extras['exception']
            out << "\n#{e['message']} (#{e['class']}): #{e['backtrace'].join("\n  ")}"
          end
          out
        end
      end

      def initialize(task, test_path_prefix, index, skip, test_blk)
        @task, @test_path_prefix, @index, @skip, @test_blk = task, test_path_prefix, index, skip, test_blk
      end

      def result
        if File.exist?(test_cache_path)
          result = JSON.parse(File.read(test_cache_path))
          Result.new(@task.context.name, @task.name, @index, result['status'], result['extras'])
        else
          Result.new(@task.context.name, @task.name, @index, "missing", {})
        end
      end

      def run_test!(fail_fast = false)
        test_name = "#{@task.name} ##{@index + 1}"
        logger.test(test_name) do
          if has_cached_result?
            logger.info "Test already has a cached result"
          else
            clear_cached_result!
            if @skip
              logger.skip_test test_name
              record_test_result "skip"
            else
              status = "error"
              extra = {}
              @task.reset!
              extra[:start_time] = Time.new.to_f
              begin
                @task.context.with_callbacks do
                  @task.instance_eval(&@test_blk)
                end
              rescue => e
                extra.merge!(exception: {backtrace: e.backtrace, message: e.message, class: e.class.to_s})
                status = "fail"
                logger.fail_test(test_name)
              else
                status = "pass"
                logger.pass_test(test_name)
              end
              extra[:end_time] = Time.new.to_f
              record_test_result status, extra
              if status == 'fail'
                puts
                puts result
                raise FailedException if fail_fast
              end
            end
          end
        end
        result
      end

      def has_cached_result?
        File.exist?(test_cache_path)
      end

      def test_cache_path
        File.join(@test_path_prefix, "#{@index}.json")
      end

      def record_test_result(status, extras = nil)
        FileUtils.mkdir_p(File.dirname(test_cache_path))
        File.open(test_cache_path, "w") do |f|
          f << {status: status, extras: extras}.to_json
        end
      end

      def clear_cached_result!
        FileUtils.rm_rf(test_cache_path)
      end

      def test_cache_path
        raise unless @task.context
        @test_cache_path ||= begin
          File.join(@test_path_prefix, "#{@index}.json")
        end
      end

      def logger
        @task.home.logger
      end
    end
  end
end