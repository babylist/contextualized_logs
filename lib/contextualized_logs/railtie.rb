
require "rails/railtie"
require 'rails'

module ContextualizedLogs
  class Railtie < ::Rails::Railtie
    railtie_name :contextualized_logs
  end
end
