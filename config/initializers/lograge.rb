return if Rails.env.test?

require 'lograge/sql/extension'
require 'json'

# pretty
module Lograge
  module Formatters
    class PrettyJson
      def call(data)
        JSON.pretty_generate(data)
      end
    end
  end
end


Rails.application.configure do
  # Lograge (format log for datadog)
  # https://docs.datadoghq.com/logs/log_collection/ruby/
  # Lograge config
  config.lograge.enabled = true
  config.colorize_logging = false
  # We are asking here to log in RAW (which are actually ruby hashes). The Ruby logging is going to take care of the JSON formatting.
  config.lograge.formatter = Lograge::Formatters::Json.new
  # for local debug, dump log in JSON pretty format
  # config.lograge.formatter = Lograge::Formatters::PrettyJson.new
  # keep existing log
  config.lograge.keep_original_rails_log = false
  # issue with existing rails logger and prefixing.. logging to different file
  # Logger::SimpleFormatter?
  config.lograge.logger = ActiveSupport::Logger.new("#{Rails.root}/log/#{Rails.env}.log")

  config.lograge.custom_options = lambda do |event|
    data = {}
    if (exception = event.payload[:exception_object])
      data = {
        # datadog naming convention
        # https://docs.datadoghq.com/logs/processing/attributes_naming_convention/#source-code
        error: {
          message: exception.message,
          kind: exception.class.to_s,
          stack: (exception.backtrace || []).join("; ")
        }
      }
    end
    correlation = Datadog.tracer.active_correlation
    data.deep_merge!(
      # Adds IDs as tags to log output
      # trace injection to correlation APM with Rails logs
      # https://docs.datadoghq.com/tracing/advanced/connect_logs_and_traces/?tab=ruby
      log_type: 'request',
      dd: {
        trace_id: correlation.trace_id,
        span_id: correlation.span_id
      },
      ddsource: ['ruby'],
      syslog: { env: Rails.env, host: Socket.gethostname },
      params: event.payload[:params].except(*Rails.application.config.filter_parameters) # ⚠️⚠️⚠️ check `config/initializers/filter_parameter_logging.rb`
    )
    data.deep_merge!(ContextualizedLogs.current_context.context) # merge current request context

    # add all job's id (not merged by current context, add it only to rquest log)
    data[:jobs] = ContextualizedLogs.current_context.enqueued_jobs_ids unless ContextualizedLogs.current_context.enqueued_jobs_ids.nil?
    data
  end
end
