require 'spec_helper'

describe EventTracer::DynamoDBLogWorker do
  let(:details) { { 'action' => 'Test', 'message' => 'Test worker' } }
  let(:aws_dynamo_client) { double }

  before do
    allow(DynamoDBClient).to receive(:call) { aws_dynamo_client }
    allow(aws_dynamo_client).to receive(:batch_write_item) { batch_write_item.is_a?(Proc) ? batch_write_item.call('request_items') : batch_write_item }
  end

  subject { described_class.new }

  context 'when input is a single item' do
    let(:batch_write_item) { true }

    it 'runs and puts details to dynamo db' do
      subject.perform(details)
    end
  end

  context 'when input is an array' do
    let(:batch_write_item) { true }
    let(:details) { [{ 'action' => 'Test', 'message' => 'TestWorker' }] }

    it 'runs and puts details to dynamo db' do
      subject.perform(details)
    end
  end

  context 'aws service error' do
    let(:stub_context) { double }
    let(:error_message) { 'service error' }
    let(:batch_write_item) do
      ->(_) { raise Aws::DynamoDB::Errors::ServiceError.new(subject, error_message) }
    end

    it 'logs to base using EventTracer' do
      expect(EventTracer).to receive(:error).with(
        loggers: %i(base), action: 'DynamoDBLogWorker',
        error: 'Aws::DynamoDB::Errors::ServiceError', message: error_message,
        app: EventTracer::APP_NAME
      )

      subject.perform(details)
    end
  end

  context 'when there are empty values in details' do
    let(:details) { {
      'action' => 'Test',
      'message' => 'Test worker',
      'nested_set' => {
        'key1' => 1,
        'nested_set_2' => {
          'key2' => ''
        }
      }
    } }
    let(:batch_write_item) { true }

    it 'does not log item attributes with nil values' do
      expect(aws_dynamo_client).to receive(:batch_write_item).with(
        request_items: {
          'test_table' => [
            {
              put_request: {
                item: {
                  'action' => 'Test',
                  'message' => 'Test worker',
                  'nested_set' => {
                    'key1' => 1,
                    'nested_set_2' => {}
                  }
                }
              }
            }
          ]
        }
      )

      subject.perform(details)
    end
  end
end
