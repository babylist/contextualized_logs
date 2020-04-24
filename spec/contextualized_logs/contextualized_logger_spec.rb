require 'rails_helper'
require 'json'
require 'timecop'

module ContextualizedLogs
  RSpec.describe ContextualizedLogger do

    before(:each) do
      Timecop.freeze(time)
      # datadog = double('Datadog')
      # stub_const('Datadog', datadog)
      # allow(datadog).to receive_message_chain(:tracer, :active_correlation, :trace_id).and_return(1)
      # allow(datadog).to receive_message_chain(:tracer, :active_correlation, :span_id).and_return(2)
    end

    after(:each) do
      Timecop.return
      read.close
    end

    let(:time) { 1.days.ago.freeze }
    let(:pipe) { IO.pipe }
    let(:write) { pipe[1] }
    let(:read) { pipe[0] }
    let(:subject) { described_class.new(write) }
    let(:raw_logs) {
      buffer = ''
      write.close
      until read.eof?
        buffer += read.read(2048)
      end
      buffer
    }
    let(:logs) do
      JSON.parse(raw_logs).deep_symbolize_keys
    end

    class MyError < StandardError
      def initialize(message, backtrace)
        super(message)
        set_backtrace backtrace
      end
    end

    it 'format log' do
      subject.info "hello"

      expect(logs.reject {|k| k == :time}).to include({
        # dd: {
        #   trace_id: 1,
        #   span_id: 2
        # },
        # ddsource: ['ruby'],
        syslog: { env: 'test', host: Socket.gethostname },
        type: 'INFO',
        log_type: 'log',
        message: 'hello'
      })
    end

    it 'includes stack' do
      subject.info "hello"

      expect(logs[:stack].any? { |line| line.include?('/spec/contextualized_logs/contextualized_logger_spec.rb') }).to eq(true)
    end

    it 'format exception' do
      subject.info MyError.new('error', ['stack1', 'stack2'])

      expect(logs[:log_type]).to eq('log')
      expect(logs[:error]).to eq(
       kind: 'ContextualizedLogs::MyError',
       message: 'error',
       stack: 'stack1; stack2'
      )
    end

    describe 'dump' do
      it 'respect severity debug (default)' do
        subject.level = :info
        subject.dump 'dump', {some_key: 'value'}, 'debug'

        expect(raw_logs).to eq('')
      end

      it 'dump message' do
        subject.level = :info
        subject.dump 'dump', {some_key: 'value'}, 'error'

        expect(logs[:log_type]).to eq('log')
        expect(logs[:message]).to eq('dump')
        expect(logs[:attributes]).to eq(
         some_key: 'value'
        )
      end

      it 'dump exception' do
        subject.level = :debug
        subject.dump MyError.new('error', ['stack1', 'stack2']), {some_key: 'value'}

        expect(logs[:log_type]).to eq('log')
        expect(logs[:error]).to eq(
         kind: 'ContextualizedLogs::MyError',
         message: 'error',
         stack: 'stack1; stack2'
        )
        expect(logs[:attributes]).to eq(
         some_key: 'value'
        )
      end
    end

    it 'inject context' do
      allow(CurrentContext).to receive(:context).and_return({context: 1})
      subject.info 'context'
      expect(logs[:context]).to eq(1)
    end

  end

end
