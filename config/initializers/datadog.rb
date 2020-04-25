Datadog.configure do |c|
  service_name = "#{Rails.env}-rails-app"
  # https://docs.datadoghq.com/tracing/trace_search_and_analytics/?tab=ruby#automatic-configuration
  # c.analytics_enabled = true

  # add runtime metrics (runtime.ruby.class_count, runtime.ruby.thread_count, runtime.ruby.gc.*)
  # http://gems.datadoghq.com/trace/docs/#Processing_Pipeline
  # c.runtime_metrics_enabled = true
  #c.tracer debug: true, hostname: '127.0.0.1', log: Logger.new(File.new('log/datadog.log', 'w+'))
  c.tracer hostname: '127.0.0.1'

  # c.use :rack, service_name: "#{service_name}-rack"
  c.use :rails, service_name: service_name, database_service: "#{service_name}-active_record", analytics_enabled: false
  # c.use :rake, service_name: "#{service_name}-rake"
  # c.use :redis, service_name: "#{service_name}-redis"
  # c.use :sidekiq, client_service_name: "#{service_name}-sidekiq-client", service_name: "#{service_name}-sidekiq-worker"
end
