require 'timecop'

describe EventTracer::DynamoDB::Logger do
  let(:log_method) { :info }

  before do
    expect(EventTracer::DynamoDB::Worker).to receive(:perform_async).with(expected_log_worker_payload)
    Timecop.freeze('2020-02-09T12:34:56Z')
  end

  after do
    Timecop.return
  end

  subject { logger.send(log_method, **payload) }

  let(:logger) { described_class.new }
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

  it { is_expected.to be_success }
end
