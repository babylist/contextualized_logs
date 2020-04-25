class ApplicationController < ActionController::API
  include DatadogSetTraceDetails # inject user_id in datadog APM trace
end
