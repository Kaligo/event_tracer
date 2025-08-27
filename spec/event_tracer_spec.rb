describe EventTracer do

  let(:mock_logger) { MockLogger.new }
  let(:mock_appsignal) { MockAppsignal.new }

  let(:loggers_args) { nil }
  let(:args) do
    {
      loggers: loggers_args,
      action: 'Action',
      message: 'Message',
      extra: 'extra',
      metrics: [:metric_1]
    }
  end

  let(:expected_log_message) { { action: 'Action', message: 'Message', extra: 'extra' } }

  subject { EventTracer }

  before do
    subject.register :base, EventTracer::BaseLogger.new(mock_logger)
    subject.register :appsignal, EventTracer::AppsignalLogger.new(mock_appsignal)
  end

  it "has a version number" do
    expect(EventTracer::VERSION).not_to be nil
  end

  shared_examples_for 'invalid_logger_args_uses_all_loggers' do
    it 'ignores invalid logger args, filters blacklisted args & triggers all messages' do
      expect(mock_logger).to receive(selected_log_method).with expected_log_message
      expect(mock_appsignal).to receive(:increment_counter).with(:metric_1, 1, {})

      result = subject.public_send(selected_log_method, **args)

      aggregate_failures do
        expect(result.records[:base].success?).to eq true
        expect(result.records[:base].error).to eq nil

        expect(result.records[:appsignal].success?).to eq true
        expect(result.records[:appsignal].error).to eq nil
      end
    end
  end

  shared_examples_for 'base_code_only_triggers_base_logger' do
    it 'only logs for the selected base logger' do
      expect(mock_logger).to receive(selected_log_method).with expected_log_message
      expect(mock_appsignal).not_to receive(:increment_counter)

      result = subject.public_send(selected_log_method, **args)

      expect(result.records[:base].success?).to eq true
      expect(result.records[:base].error).to eq nil

      expect(result.records[:appsignal]).to eq nil
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Logging for #{log_type}" do
      let(:selected_log_method) { log_type }

      context "Specific code triggers only selected logger" do
        let(:loggers_args) { [:base] }
        it_behaves_like 'base_code_only_triggers_base_logger'
      end

      context "Invalid logger codes specified" do
        [
          nil,
          :invalid_logger,
          :base,
          :appsignal,
          [:invalid_logger],
          Object.new,
          'String',
          1
        ].each do |invalid_logger_args|
          context "Logging for #{log_type}, Invalid argument #{invalid_logger_args}" do
            let(:loggers_args) { invalid_logger_args }
            it_behaves_like 'invalid_logger_args_uses_all_loggers'
          end
        end
      end

      context 'Logger fails when error occurs' do
        before do
          expect(mock_logger).to receive(selected_log_method).and_raise(RuntimeError.new('Runtime error in base logger'))
        end

        it 'raises the original error' do
          expect { subject.public_send(selected_log_method, **args) }.to raise_error do |error|
            expect(error).to be_a(RuntimeError)
            expect(error.message).to eq('Runtime error in base logger')
          end
        end

        context 'when there is a configured error handler' do
          let(:io) { StringIO.new }

          before do
            EventTracer::Config.config.error_handler = ->(error, payload) { io.puts error, payload }
          end

          after do
            EventTracer::Config.reset_config
          end

          it 'handles the original error gracefully and sets log failure result' do
            result = subject.public_send(selected_log_method, **args)
            expect(result.records[:base].success?).to eq false
            expect(result.records[:base].error).to eq 'Runtime error in base logger'

            expect(result.records[:appsignal].success?).to eq true
            expect(result.records[:appsignal].error).to eq nil

            expect(io.string).to include('Runtime error in base logger')
          end
        end
      end
    end
  end

  describe '.flush_all' do
    around do |example|
      original_loggers = EventTracer.send(:instance_variable_get, :@loggers).dup
      EventTracer.send(:instance_variable_set, :@loggers, {})
      example.run
      EventTracer.send(:instance_variable_set, :@loggers, original_loggers)
    end

    context 'when no buffered loggers are registered' do
      before do
        EventTracer.register :base, EventTracer::BaseLogger.new(MockLogger.new)
      end

      it 'returns an array with only nils (no buffered loggers)' do
        results = EventTracer.flush_all
        expect(results).to be_a(Array)
        expect(results.compact).to be_empty
      end
    end

    context 'when buffered and non-buffered loggers are registered' do
      let(:buffered_logger) do
        EventTracer::BufferedLogger.new(
          buffer: double('Buffer'),
          log_processor: double('LogProcessor'),
          worker: double('Worker')
        )
      end

      let(:log_result) { EventTracer::LogResult.new(true) }

      before do
        EventTracer.register :base, EventTracer::BaseLogger.new(MockLogger.new)
        EventTracer.register :buffered, buffered_logger
        allow(buffered_logger).to receive(:flush).and_return(log_result)
      end

      it 'flushes only buffered loggers and returns their results' do
        results = EventTracer.flush_all

        expect(buffered_logger).to have_received(:flush).once
        expect(results.compact).to eq([log_result])
      end
    end
  end
end
