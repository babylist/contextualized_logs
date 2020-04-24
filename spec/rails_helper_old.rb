ENV["RAILS_ENV"] ||= 'test'

require 'spec_helper'
require 'rails'
# require "contextualized_logs/current_context"
require 'action_controller/railtie' # allows ActionController::Base
require 'action_dispatch' # allows ActionDispatch::Routing
# action_dispatch/routing.rb
# crucial part here:
require 'rspec/rails'
# require 'rspec/rails'
# require 'sidekiq/testing'
# require 'super_diff/rspec-rails'
#
# if Settings.SIDEKIQ_RUN_TEST_MODE == 'on'
#   Sidekiq::Testing.fake!
# end
#
# # ENV vars don't load when running specs from within the engine; manually load them here
# Dotenv.load(
#     File.expand_path("../.env.#{Rails.env}", __FILE__),
#     File.expand_path("../.env", __FILE__)
# )
#
# Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
# Dir[Rails.root.join("spec/**/shared_examples/**/*.rb")].each {|f| require f}
#
# ActiveRecord::Migration.maintain_test_schema!
#
# RSpec::Matchers.define_negated_matcher :not_change, :change
#
RSpec.configure do |config|
#   config.infer_spec_type_from_file_location!
#   config.use_transactional_fixtures = true
#
#   config.before(:suite) do
#     BLFulfillment::InventoryLevel.delete_all
#     BLFulfillment::InventoryLocation.delete_all
#     BLFulfillment::Supplier.delete_all
#     BLRegistry::Product.delete_all
#     BLRegistry::ProductAttribute.delete_all
#     BLRegistry::PromotionalCreditCampaign.delete_all
#     BLRegistry::Registry.delete_all
#     BLRegistry::User.delete_all
#     BLRegistry::UserRegistry.delete_all
#
#     # Setup required database seed records
#     RSpec::Mocks.with_temporary_scope do
#       # Setup default inventory location
#       FactoryBot.create(:inventory_location, name: BLFulfillment::InventoryLocation::NAME_BL_SAC_WAREHOUSE, priority: 1)
#       # do this for dotcom
#       # Setup the electronic gift card product
#       # Stub any external calls that are triggered by creating the electronic gift card GP
#       allow_any_instance_of(BLRegistry::GenericProduct).to receive(:update_search_engine)
#       FactoryBot.create(:product, :bl_product, id: Settings.ELECTRONIC_GIFT_CARD_PRODUCT_ID.to_i, product_type: BLRegistry::Product::TYPE_DIGITAL)
#       # Setup the CS happiness campaign
#       FactoryBot.create(:promotional_credit_campaign, id: BLRegistry::PromotionalCreditCampaign::CAMPAIGN_ID_CUSTOMER_HAPPINESS)
#     end
#   end
#
  config.before(:each) do
    ContextualizedLogs::CurrentContext.reset
  end
#
end
