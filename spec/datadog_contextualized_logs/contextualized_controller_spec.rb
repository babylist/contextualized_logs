# coding: utf-8
require "rails_helper"

module DatadogContextualizedLogs

  class Controller < ActionController::Base
     include ContextualizedController

     def action_name
       'action'
     end

     def before_action(names, block)
     end
  end

  RSpec.describe ContextualizedController do
    describe '.contextualize_requests' do
      it 'should set request details' do
        fake_controller = Controller.new
        fake_request = double('request',
          uuid: 'uuid',
          origin: 'origin',
          user_agent: 'user_agent',
          referer: 'referer',
          ip: 'ip',
          remote_ip: 'remote_ip',
          remote_addr: 'remote_addr',
          x_forwarded_for: 'x_forwarded_for',
          xhr?: true
        )
        fake_logger = double('logger')
        allow(fake_controller).to receive(:request).and_return(fake_request)

        allow(fake_controller).to receive(:logger).and_return(fake_logger)
        allow(fake_logger).to receive(:dump_error)
        fake_controller.contextualize_requests
        expect(CurrentContext.context).to eq(
          resource_name: 'datadogcontextualizedlogs::controller_action',
            http: {
              origin: 'origin',
              referer: 'referer',
              request_id: 'uuid',
              useragent: 'user_agent',
            },
            network: {
              client: {
                ip: 'ip',
                remote_ip: 'remote_ip',
                remote_addr: 'remote_addr',
                x_forwarded_for: 'x_forwarded_for'

              }
            }
        )
      end
    end
  end
end
