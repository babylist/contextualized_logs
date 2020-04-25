module DatadogSetTraceDetails
  extend ActiveSupport::Concern

  included do
    before_action :set_trace_tags, unless: -> { Rails.env.development? }
  end

  def set_trace_tags
    begin
      # set log context as (Datadog) APM trace tags
      tracer = Datadog.configuration[:rails][:tracer]
      span = tracer.active_span
      dotted_hash(ContextualizedLogger.config.current_context).each do |k, v|
        span.set_tag(k, v)
      end
    rescue StandardError => e
      Rails.logger.info "Error setting trace tags #{e}"
    end
  end

  private

  # {http: {uuid: 123}} => {http.uuid: 123}
  # could be added to Hash
  def dotted_hash(hash, recursive_key = "")
    hash.each_with_object({}) do |(k, v), ret|
      key = recursive_key + k.to_s
      if v.is_a? Hash
        ret.merge! dotted_hash(v, key + ".")
      else
        ret[key] = v
      end
    end
  end

end
