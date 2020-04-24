module ContextualizedLogs
  # https://github.com/mperham/sidekiq/wiki/Middleware
  module Sidekiq
    module Middleware
      module Server
        # https://github.com/mperham/sidekiq/wiki/Middleware
        class RestoreCurrentContext
          # @param [Object] worker the worker instance
          # @param [Hash] job the full job payload
          #   * @see https://github.com/mperham/sidekiq/wiki/Job-Format
          # @param [String] queue the name of the queue the job was pulled from
          # @yield the next middleware in the chain or worker `perform` method
          # @return [Void]
          def call(worker, job, queue)
            worker_klass = worker.class
            if worker_klass.include?(ContextualizedWorker)
              job_context_json = job['context']
              current_context = worker_klass.current_context
              current_context.from_json(job_context_json) if job_context_json
              current_context.current_job_id = job['jid']
              current_context.worker = worker.class.to_s
              # https://github.com/mperham/sidekiq/wiki/Job-Format
              current_context.worker_args = worker_klass.contextualize_args(job['args']) if worker_klass.respond_to?(:contextualize_args) && job['args']
              current_context.contextualized_model_enabled = worker_klass.contextualized_model_enabled
              if worker_klass.contextualized_worker_enabled
                Rails.logger.info "sidekiq: performing job #{worker_klass}: #{job['jid']}, on queue #{queue}"
                yield
                Rails.logger.info "sidekiq: completing job #{worker_klass}: #{job['jid']}, on queue #{queue}"
              end
            else
              yield
            end
          rescue StandardError => e
            if worker_klass.include?(ContextualizedWorker)
              Rails.logger.error "sidekiq: failure job #{worker.class}: #{job['jid']}, on queue #{queue}: #{e}"
            end
            raise e
          end
        end
      end
    end
  end
end
