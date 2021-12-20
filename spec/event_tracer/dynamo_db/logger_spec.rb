require 'timecop'

describe EventTracer::DynamoDB::Logger do
  let(:log_method) { :info }

  let(:logger) { described_class.new }

  subject { logger.info(**payload) }

  before do
    Timecop.freeze('2020-02-09T12:34:56Z')
  end

  after do
    Timecop.return
  end

  context 'when payload is valid' do
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
        app: EventTracer::Config.config.app_name
      }]
    end

    before do
      expect(EventTracer::DynamoDB::Worker).to receive(:perform_async).with(expected_log_worker_payload)
    end

    it { is_expected.to be_success }
  end

  context 'when payload is invalid' do
    let(:payload) do
      {
        message: "\xAE",
        action: 'Testing',
        log_type: :info
      }
    end
    let(:expected_log_worker_payload) do
      {
        message: 'source sequence is illegal/malformed utf-8',
        action: 'EventTracer::DynamoDB::Logger',
        error: 'JSON::GeneratorError',
        loggers: [:base],
        app: EventTracer::Config.config.app_name,
        payload: [hash_including(payload)]
      }
    end

    before do
      expect(EventTracer).to receive(:warn).with(expected_log_worker_payload)
    end

    it { is_expected.to be_success }
  end
end
