require 'active_support'

module DatadogContextualizedLogs
  # custom logger for datadog
  # logging in json format with log enrichment
  # support Rails.logger.dump('msg', hash)

  class ContextualizedLogger < ActiveSupport::Logger
    def initialize(*args)
      super(*args)
      @formatter = formatter
    end

    def dump(msg, attributes, severity = :info)
      # log message with attributes as structured dump attributes
      send(severity, { msg: msg, attributes: attributes })
    end

    def dump_error(msg, attributes)
      dump(msg, attributes, :error)
    end

    def formatter
      Proc.new{|severity, timestamp, progname, msg|
        # format (and enrich) log in JSON format (-> Datadog)
        # https://docs.datadoghq.com/logs/processing/attributes_naming_convention/#source-code
        correlation = Datadog.tracer.active_correlation
        data = {
          dd: {
            trace_id: correlation.trace_id,
            span_id: correlation.span_id
          },
          ddsource: ['ruby'],
          syslog: { env: Rails.env, host: 'a' },
          type: severity.to_s,
          time: timestamp
        }
        data[:stack] = Kernel.caller.
          # map { |caller| caller.gsub(/#{Rails.root}/, '') }.
          # reject { |caller| caller.start_with?('/usr/local') || caller.include?('/shared/bundle/') || caller.start_with?('/Users/') }.
          first(15)
        data[:log_type] = 'log'
        data.merge!(parse_msg(msg)) # parse message (string, hash, error, ...)
        data.merge!(CurrentContext.context) # merge current request context
        data.to_json + "\n"
      }
    end

    private

    def parse_msg(msg)
      data = {}
      case msg
      when Hash
        # used by logger.dump(msg|error, attributes = {})
        if msg.include?(:attributes)
          # adding message as log attributes if is a hash
          data.merge!(parse_error(msg[:msg]))
          data[:attributes] = msg[:attributes]
        else
          data.merge!(parse_error(msg))
        end
      else
        data.merge!(parse_error(msg))
      end
      data
    end

    def parse_error(msg)
      data = {}
      case msg
      when ::Exception
        # format data to be interpreted as an error logs by datadog
        data[:error] = {
          kind: msg.class.to_s,
          message: msg.message,
          stack: (msg.backtrace || []).join('; ')
        }
      else
        data[:message] = msg.to_s
      end
      data
    end
  end

end
