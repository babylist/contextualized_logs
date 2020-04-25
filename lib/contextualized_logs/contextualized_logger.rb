require 'active_support'

module ContextualizedLogs
  # custom logger for
  # logging in json format with log enrichment
  # support Rails.logger.dump('msg', hash)

  class ContextualizedLogger < ActiveSupport::Logger
    class << self
      attr_accessor :formatter
      attr_writer :current_context

      def current_context
        @current_context || ContextualizedLogs.config.current_context
      end

      def default_formatter
        proc do |severity, timestamp, progname, msg|
          data = {
            syslog: { env: Rails.env, host: Socket.gethostname },
            type: severity.to_s,
            time: timestamp
          }
          # data[:stack] = Kernel.caller.
          #   map { |caller| caller.gsub(/#{Rails.root}/, '') }.
          #   reject { |caller| caller.start_with?('/usr/local') || caller.include?('/shared/bundle/') || caller.start_with?('/Users/') }.
          #   first(15)
          data[:log_type] = 'log'
          data.merge!(parse_msg(msg)) # parse message (string, hash, error, ...)
          data.merge!(current_context.context) # merge current request context
          data.to_json + "\n"
        end
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
          # format data to be interpreted as an error logs by
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

    attr_accessor :formatter

    def initialize(*args)
      super(*args)
      @formatter = self.class.formatter || self.class.default_formatter
    end

    def dump(msg, attributes, severity = :info)
      # log message with attributes as structured dump attributes
      send(severity, { msg: msg, attributes: attributes })
    end

    def dump_error(msg, attributes)
      dump(msg, attributes, :error)
    end
  end

end
