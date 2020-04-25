# Sidekiq::Extensions.enable_delay!

# Perform Sidekiq jobs immediately in development, so you don't have to run a separate process.
require 'sidekiq'
# Sidekiq::Testing.inline!

# Setup throttling for dealing with rate-limited APIs
# require 'sidekiq/throttled'
# Sidekiq::Throttled.setup!

# Sidekiq.configure_server do |config|
#   config.redis = { url: 'redis://127.0.0.1:6379/1' }
#   config.server_middleware do |chain|
#     chain.add ContextualizedLogs::Sidekiq::Middleware::Server::RestoreCurrentContext
#   end
# end
#
# Sidekiq.configure_client do |config|
#   config.redis = { url: 'redis://127.0.0.1:6379/1' }
#   config.client_middleware do |chain|
#     chain.add ContextualizedLogs::Sidekiq::Middleware::Client::InjectCurrentContext
#   end
# end
