require 'spec_helper'

describe EventTracer::BaseLogger do

  let(:mock_logger) { MockLogger.new }

  subject { EventTracer::BaseLogger.new(mock_logger) }

  shared_examples_for 'send_simple_message' do
    it 'sends formatted simple message' do
      expect(mock_logger).to receive(expected_call).with('[TestAction] Simple message only')
      subject.send(expected_call, action: 'TestAction', simple_message: 'Simple message only')
    end
  end

  shared_examples_for 'send_formatted_json_message' do
    let(:payload) { { message: 'Message', other_data: 'Burke' } }

    it 'sends formatted payload message' do
      expect(mock_logger).to receive(expected_call).with("[TestAction] #{payload.to_json}")
      subject.send(expected_call, **payload.merge(action: 'TestAction'))
    end
  end

  shared_examples_for 'no_message_data' do
    it 'does not log if no message data sent' do
      expect(subject.send(expected_call, action: 'InvalidAction')).to eq false
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'send_simple_message'
      it_behaves_like 'send_formatted_json_message'
      it_behaves_like 'no_message_data'
    end
  end

end