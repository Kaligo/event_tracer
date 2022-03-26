require 'spec_helper'

describe EventTracer::DynamoDB::Worker do
  before do
    EventTracer::Config.configure do |config|
      config.app_name = 'test_app'
      config.dynamo_db_table_name = 'test_table'
    end
  end

  after do
    EventTracer::Config.reset_config
  end

  let(:details) { { 'action' => 'Test', 'message' => 'Test worker' } }
  let(:aws_dynamo_client) do
    Aws::DynamoDB::Client.new(stub_responses: {
      batch_write_item: batch_write_item
    })
  end

  subject { described_class.new(aws_dynamo_client) }

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
        loggers: %i(base), action: 'DynamoDBWorker',
        error: 'Aws::DynamoDB::Errors::ServiceError', message: error_message,
        app: EventTracer::Config.config.app_name
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
