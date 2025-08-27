describe EventTracer::BufferedLogger do
  let(:buffer) { instance_double(EventTracer::Buffer) }
  let(:log_processor) { double('LogProcessor') }
  let(:worker) { double('Worker') }
  let(:logger) do
    described_class.new(
      buffer: buffer,
      log_processor: log_processor,
      worker: worker
    )
  end

  describe '#info' do
    let(:action) { 'Action' }
    let(:message) { 'this is a message' }
    let(:args) { { random_data: 'random' } }
    let(:payload) { { data: 'data' } }
    subject { logger.info(action: action, message: message, **args) }

    before do
      expect(log_processor).to receive(:call)
        .with(:info, action: action, message: message, args: args).and_return(payload)
    end

    context 'when buffer is not full' do
      before do
        expect(buffer).to receive(:add).with(payload).and_return(true)
      end

      it { is_expected.to be_success }
    end

    context 'when buffer is full and there are no JSON error' do
      let(:all_payloads) { [other_payload, payload] }
      let(:other_payload) { { data: 'other' } }

      before do
        expect(buffer).to receive(:add).with(payload).and_return(false)
        expect(buffer).to receive(:flush).and_return([other_payload])
        expect(worker).to receive(:perform_async).with(all_payloads)
      end

      it { is_expected.to be_success }
    end

    context 'when buffer is full and there is JSON generator error' do
      let(:all_payloads) { [other_payload, payload] }
      let(:other_payload) { { data: "\xAE" } }

      before do
        expect(buffer).to receive(:add).with(payload).and_return(false)
        expect(buffer).to receive(:flush).and_return([other_payload])
        expect(worker).to receive(:perform_async)
          .with(all_payloads).and_raise(JSON::GeneratorError.new('invalid json'))
        expect(worker).to receive(:perform_async).with([payload])
      end

      it { is_expected.to be_success }
    end

    context 'when buffer is full and there is sidekiq error' do
      let(:all_payloads) { [other_payload, payload] }
      let(:other_payload) { { 'action' => 'action', 'app' => 'guardhouse', 'metrics' => [:metric_1] } }

      before do
        expect(buffer).to receive(:add).with(payload).and_return(false)
        expect(buffer).to receive(:flush).and_return([other_payload])
        expect(worker).to receive(:perform_async)
          .with(all_payloads).and_raise(ArgumentError)
      end

      it 'should raise error' do
        expect { subject }.to raise_error { |error|
          expect(error).to be_a EventTracer::ErrorWithPayload
          expect(error.cause).to be_a ArgumentError
          expect(error.payload).to eq(all_payloads)
        }
      end
    end
  end

  describe '#flush' do
    subject { logger.flush }

    context 'when buffer is empty' do
      before do
        expect(buffer).to receive(:flush).and_return([])
        expect(worker).not_to receive(:perform_async)
      end

      it 'returns success' do
        expect(subject).to be_success
      end
    end

    context 'when buffer returns nil' do
      before do
        expect(buffer).to receive(:flush).and_return(nil)
        expect(worker).not_to receive(:perform_async)
      end

      it 'returns success' do
        expect(subject).to be_success
      end
    end

    context 'when buffer has payloads' do
      let(:payloads) { [{ a: 1 }, { b: 2 }] }

      before do
        expect(buffer).to receive(:flush).and_return(payloads)
        expect(worker).to receive(:perform_async).with(payloads)
      end

      it 'returns success and enqueues payloads' do
        expect(subject).to be_success
      end
    end

    context 'when there is JSON generator error' do
      let(:invalid_payload) { { data: "\xAE" } }
      let(:valid_payload) { { data: 'ok' } }
      let(:payloads) { [invalid_payload, valid_payload] }

      before do
        expect(buffer).to receive(:flush).and_return(payloads)
        expect(worker).to receive(:perform_async)
          .with(payloads).and_raise(JSON::GeneratorError.new('invalid json'))
        expect(EventTracer).to receive(:warn).with(hash_including(
          loggers: [:base],
          action: 'EventTracer::BufferedLogger',
          app: EventTracer::Config.config.app_name,
          error: 'JSON::GeneratorError',
          payload: [invalid_payload]
        ))
        expect(worker).to receive(:perform_async).with([valid_payload])
      end

      it 'filters invalid payloads and returns success' do
        expect(subject).to be_success
      end
    end

    context 'when there is a non-JSON error' do
      let(:payloads) { [{ data: 'bad' }] }

      before do
        expect(buffer).to receive(:flush).and_return(payloads)
        expect(worker).to receive(:perform_async)
          .with(payloads).and_raise(ArgumentError, 'boom')
        expect(EventTracer).to receive(:warn).with(hash_including(
          loggers: [:base],
          action: 'EventTracer::BufferedLogger',
          app: EventTracer::Config.config.app_name,
          error: 'EventTracer::ErrorWithPayload',
          message: 'boom',
          payload: payloads
        ))
      end

      it 'does not raise' do
        expect { subject }.not_to raise_error
        expect(subject).not_to be_success
      end
    end
  end
end
