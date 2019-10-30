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
      appsignal: { increment_counter: { counter_1: 1 } }
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
      expect(mock_appsignal).to receive(:increment_counter).with(:counter_1, 1)

      result = subject.send(selected_log_method, **args)

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

      result = subject.send(selected_log_method, **args)

      expect(result.records[:base].success?).to eq true
      expect(result.records[:base].error).to eq nil

      expect(result.records[:appsignal]).to eq nil
    end
  end

  shared_examples_for 'error_in_logger_service_fails_gracefully' do
    before do
      allow(mock_logger).to receive(selected_log_method).and_raise(RuntimeError.new('Runtime error in base logger'))
    end

    it 'marks the logging outcome as false' do
      result = subject.send(selected_log_method, **args)

      expect(result.records[:base].success?).to eq false
      expect(result.records[:base].error).to eq 'Runtime error in base logger'

      expect(result.records[:appsignal].success?).to eq true
      expect(result.records[:appsignal].error).to eq nil
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
          [],
          :invalid_logger,
          :base,
          :appsignal,
          [:invalid_logger],
          {},
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

      context 'Logger fails gracefully when exception occurs' do
        it_behaves_like 'error_in_logger_service_fails_gracefully'
      end
    end
  end
end
