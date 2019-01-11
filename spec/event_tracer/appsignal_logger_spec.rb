require 'spec_helper'

describe EventTracer::AppsignalLogger do

  INVALID_PAYLOADS ||= [
    nil,
    [],
    Object.new,
    'string',
    10,
    :invalid_payload
  ].freeze

  let(:appsignal_payload) { nil }
  let(:mock_appsignal) { MockAppsignal.new }

  subject { EventTracer::AppsignalLogger.new(mock_appsignal) }

  shared_examples_for 'rejects_invalid_appsignal_args' do
    INVALID_PAYLOADS.each do |appsignal_value|
      context "Invalid appsignal top-level args" do
        let(:appsignal_payload) { appsignal_value }

        it 'rejects the payload when invalid appsignal values are given' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)

          result = subject.send(expected_call, appsignal: appsignal_payload)

          expect(result.success?).to eq false
          expect(result.error).to eq 'Invalid appsignal config'
        end
      end
    end
  end

  shared_examples_for 'skip_processing_empty_appsignal_args' do
    let(:appsignal_payload) { {} }

    it 'skips any metric processing' do
      expect(mock_appsignal).not_to receive(:increment_counter)
      expect(mock_appsignal).not_to receive(:add_distribution_value)
      expect(mock_appsignal).not_to receive(:set_gauge)

      result = subject.send(expected_call, appsignal: appsignal_payload)

      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  shared_examples_for 'processes_hashed_inputs' do
    let(:appsignal_payload) { {
      increment_counter: { 'Counter_1' => 1, 'Counter_2' => 2 },
      add_distribution_value: { 'Distribution_1' => 10 },
      set_gauge: { 'Gauge_1' => 100 }
    } }

    it 'processes each hash keyset as a metric iteration' do
      expect(mock_appsignal).to receive(:increment_counter).with('Counter_1', 1)
      expect(mock_appsignal).to receive(:increment_counter).with('Counter_2', 2)
      expect(mock_appsignal).to receive(:add_distribution_value).with('Distribution_1', 10)
      expect(mock_appsignal).to receive(:set_gauge).with('Gauge_1', 100)

      result = subject.send(expected_call, appsignal: appsignal_payload)

      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  shared_examples_for "rejects_invalid_metric_args" do
    EventTracer::AppsignalLogger::SUPPORTED_METRICS.each do |metric|
      INVALID_PAYLOADS.each do |payload|
        context "Invalid metric values for #{metric}: #{payload}" do
          let(:appsignal_payload) { { metric => payload } }

          it 'rejects the payload when invalid appsignal values are given' do
            expect(mock_appsignal).not_to receive(:increment_counter)
            expect(mock_appsignal).not_to receive(:add_distribution_value)
            expect(mock_appsignal).not_to receive(:set_gauge)

            result = subject.send(expected_call, appsignal: appsignal_payload)

            expect(result.success?).to eq false
            expect(result.error).to eq "Appsignal metric #{metric} invalid"
          end
        end
      end
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'processes_hashed_inputs'
      it_behaves_like 'skip_processing_empty_appsignal_args'
      it_behaves_like 'rejects_invalid_appsignal_args'
      it_behaves_like 'rejects_invalid_metric_args'
    end
  end

end
