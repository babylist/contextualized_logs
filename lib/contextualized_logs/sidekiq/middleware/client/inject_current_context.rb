module ContextualizedLogs
  # https://github.com/mperham/sidekiq/wiki/Middleware
  module Sidekiq
    module Middleware
      module Client
        class InjectCurrentContext
          # @param [String, Class] worker_class the string or class of the worker class being enqueued
          # @param [Hash] job the full job payload
          #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
          # @param [String] queue the name of the queue the job was pulled from
          # @param [ConnectionPool] redis_pool the redis pool
          # @return [Hash, FalseClass, nil] if false or nil is returned,
          #   the job is not to be enqueued into redis, otherwise the block's
          #   return value is returned
          # @yield the next middleware in the chain or the enqueuing of the job
          def call(worker_class, job, queue, redis_pool)
            # https://github.com/rails/rails/issues/37526
            # current attribute should be clear between jobs
            # no need to `Current.reset`
            worker_klass = worker_class.is_a?(String) ? worker_class.constantize : worker_class
            if worker_klass.include?(ContextualizedWorker)
              current_context = ContextualizedWorker.current_context
              current_context.enqueued_jobs_ids ||= []
              current_context.enqueued_jobs_ids << job['jid']
              current_context.contextualize_model_enabled = worker_klass.contextualize_model_enabled
              if worker_klass.contextualize_worker_enabled
                job['context'] = current_context.to_json
                Rails.logger.info "sidekiq: enqueing job #{worker_class}: #{job['jid']}, on queue: #{queue}"
                Rails.logger.dump('Injecting context', JSON.parse(current_context.to_json), :debug)
              end
            end
            yield
          end
        end
      end
    end
  end
end
