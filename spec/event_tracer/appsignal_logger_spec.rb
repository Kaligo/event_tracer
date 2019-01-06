require 'spec_helper'

describe EventTracer::AppsignalLogger do

  let(:metric_payload) { nil }
  let(:appsignal_payload) { {
    increment_counter: metric_payload,
    add_distribution_value: metric_payload,
    set_gauge: metric_payload
  } }
  let(:mock_appsignal) { MockAppsignal.new }

  subject { EventTracer::AppsignalLogger.new(mock_appsignal) }

  shared_examples_for 'rejects_invalid_metric_payload' do
    [
      nil,
      [],
      1,
      "String",
      Object.new,
      {}
    ].each do |invalid_input|
      context "Invalid metric payload: #{invalid_input}" do
        let(:metric_payload) { invalid_input }

        it 'rejects non-hash input' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)
          subject.send(expected_call, appsignal: appsignal_payload)
        end
      end
    end
  end

  shared_examples_for 'rejects_blank_appsignal_payload' do
    [
      nil,
      {}
    ].each do |blank_payload|
      context "Blank appsignal payload #{blank_payload}" do
        let(:appsignal_payload) { blank_payload }

        it 'does not process with no appsignal payload given' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)
          subject.send(expected_call, appsignal: appsignal_payload)
        end
      end
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

      subject.send(expected_call, appsignal: appsignal_payload)
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'rejects_invalid_metric_payload'
      it_behaves_like 'rejects_blank_appsignal_payload'
      it_behaves_like 'processes_hashed_inputs'
    end
  end

end
