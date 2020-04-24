# https://github.com/rails/rails/pull/29180
# storing global request info
require 'active_support'

module ContextualizedLogs
  class CurrentContext < ActiveSupport::CurrentAttributes
    # ⚠️ do not use this class to store any controller specific info..

    attribute \
      :request_uuid, :request_user_agent, :request_origin, :request_referer, :request_xhr, # request
      :current_job_id, :enqueued_jobs_ids, :worker, :worker_args, # sidekiq
      :request_remote_ip, :request_ip, :request_remote_addr, :request_x_forwarded_for, # ips
      :errors,
      :contextualized_model_enabled, # enable model context values
      :context_values, :context_values_count, # context values
      :resource_name # controller_action to correlate APM metrics

    MAX_CONTEXT_VALUES = 100

    def self.context
      # https://docs.hq.com/logs/processing/attributes_naming_convention/#source-code

      data = {}

      data[:resource_name] = resource_name unless resource_name.nil?

      #  normalized
      data[:http] = {}
      data[:http][:referer] = request_referer unless request_referer.nil?
      data[:http][:request_id] = request_uuid unless request_uuid.nil?
      data[:http][:useragent] = request_user_agent unless request_user_agent.nil?
      data[:http][:origin] = request_origin unless request_origin.nil?
      data.delete(:http) if data[:http].empty?

      #  normalized
      data[:network] = { client: {} }
      data[:network][:client][:ip] = request_ip unless request_ip.nil?
      data[:network][:client][:remote_addr] = request_remote_addr unless request_remote_addr.nil?
      data[:network][:client][:remote_ip] = request_remote_ip unless request_remote_ip.nil?
      data[:network][:client][:x_forwarded_for] = request_x_forwarded_for unless request_x_forwarded_for.nil?
      data.delete(:network) if data[:network][:client].empty?

      # eventual error response
      #  normalized
      data[:errors] = errors unless errors.nil?

      # context_values
      unless context_values.nil?
        if context_values.is_a?(Hash) && !context_values.empty?
          data[:context_values] = {}
          context_values.each { |k, v| data[:context_values][k.to_sym] = v }
        end
      end

      unless current_job_id.nil? && worker.nil?
        data[:job] = { id: current_job_id, worker: worker }
        data[:job][:args] = worker_args if worker_args
      end

      data
    end

    def self.to_json
      attributes.to_json
    end

    def self.add_context(key, value)
      self.context_values_count ||= 0
      self.context_values_count += 1
      if self.context_values_count >= MAX_CONTEXT_VALUES
        Rails.logger.warn('high number of context values') if self.context_values_count == MAX_CONTEXT_VALUES
        return

      end
      self.context_values ||= {}
      self.context_values[key] ||= []
      unless self.context_values[key].include?(value)
        self.context_values[key] << value
      end
    end

    def self.from_json(json)
      return unless json

      begin
        values = JSON.parse(json).deep_symbolize_keys
        values.each { |k, v| send("#{k}=", v) }
      rescue
      end
    end

    def self.add_error(error)
      return if error.nil?

      self.errors ||= []
      self.errors << error
    end
  end
end
