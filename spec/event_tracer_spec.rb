describe EventTracer do

  let(:tracer_logger) { EventTracer::BaseLogger.new(MockLogger.new) }
  let(:tracer_appsignal) { EventTracer::AppsignalLogger.new(MockAppsignal.new) }

  let(:loggers_args) { nil }
  let(:args) { { loggers: loggers_args, message: 'Message' } }

  subject { EventTracer }

  before do
    subject.register :base, tracer_logger
    subject.register :appsignal, tracer_appsignal
  end

  it "has a version number" do
    expect(EventTracer::VERSION).not_to be nil
  end

  shared_examples_for 'invalid_logger_args_uses_all_loggers' do
    it 'ignores invalid logger args and triggers all messages' do
      expect(tracer_logger).to receive(selected_log_method).with(message: 'Message')
      expect(tracer_appsignal).to receive(selected_log_method).with(message: 'Message')

      expect(subject.send(selected_log_method, **args)).to eq true
    end
  end

  shared_examples_for 'base_code_only_triggers_base_logger' do
    it 'only logs for the selected base logger' do
      expect(tracer_logger).to receive(selected_log_method).with(message: 'Message')
      expect(tracer_appsignal).not_to receive(selected_log_method).with(message: 'Message')

      expect(subject.send(selected_log_method, **args)).to eq true
    end
  end

  shared_examples_for 'error_in_logger_service_fails_gracefully' do
    before do
      allow(tracer_logger).to receive(selected_log_method).and_raise(RuntimeError.new)
    end

    it 'marks the logging outcome as false' do
      expect(subject.send(selected_log_method, **args)).to eq false
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
