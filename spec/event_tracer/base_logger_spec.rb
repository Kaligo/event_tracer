require 'spec_helper'

describe EventTracer::BaseLogger do

  let(:mock_logger) { MockLogger.new }

  subject { EventTracer::BaseLogger.new(mock_logger) }

  shared_examples_for 'send_formatted_json_message' do
    let(:payload) { { type: 'info', other_data: 'Burke' } }

    it 'sends formatted payload message' do
      expect(mock_logger).to receive(expected_call).with("[TestAction] Message #{payload.to_json}")
      result = subject.send(expected_call, **payload.merge(action: 'TestAction', message: 'Message'))
    
      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'send_formatted_json_message'
    end
  end

end