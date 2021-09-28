require 'timecop'

describe EventTracer::DynamoDBLogger do
  let(:log_method) { :info }

  before do
    expect(EventTracer::DynamoDBLogWorker).to receive(:perform_async).with(expected_log_worker_payload)
    Timecop.freeze('2020-02-09T12:34:56Z')
  end

  after do
    Timecop.return
  end

  subject { logger.send(log_method, **payload) }

  context 'when buffer is not being used' do
    let(:logger) { described_class.new }
    let(:payload) do
      {
        message: 'Some message',
        action: 'Testing',
        log_type: :info
      }
    end
    let(:expected_log_worker_payload) do
      {
        message: 'Some message',
        action: 'Testing',
        log_type: :info,
        timestamp: '2020-02-09T12:34:56.000000Z',
        app: EventTracer::APP_NAME
      }
    end

    it { is_expected.to be_success }
  end

  context 'when buffer is being used' do
    let(:buffer) { EventTracer::Buffer.new(buffer_size: 0) } # set buffer to 0 so that one log will still flush buffer
    let(:logger) { described_class.new(buffer) }
    let(:payload) do
      {
        message: 'Some message',
        action: 'Testing',
        log_type: :info
      }
    end
    let(:expected_log_worker_payload) do
      [{
        message: 'Some message',
        action: 'Testing',
        log_type: :info,
        timestamp: '2020-02-09T12:34:56.000000Z',
        app: EventTracer::APP_NAME
      }]
    end

    it { is_expected.to be_success }
  end
end
