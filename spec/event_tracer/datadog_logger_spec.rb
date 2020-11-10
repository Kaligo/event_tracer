require 'spec_helper'

describe EventTracer::DatadogLogger do

  INVALID_PAYLOADS ||= [
    nil,
    [],
    Object.new,
    'string',
    10,
    :invalid_payload
  ].freeze

  let(:datadog_payload) { nil }
  let(:mock_datadog) { MockDatadog.new }

  subject { EventTracer::DatadogLogger.new(mock_datadog) }

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      context 'processes_hashed_inputs' do
        let(:datadog_payload) do
          {
            count: { 'Counter_1' => 1, 'Counter_2' => 2 },
            distribution: { 'Distribution_1' => 10 },
            set: { 'Set_1' => 100 },
            gauge: { 'Gauge_1' => 100 }
          }
        end

        it 'processes each hash keyset as a metric iteration' do
          expect(mock_datadog).to receive(:count).with('Counter_1', 1)
          expect(mock_datadog).to receive(:count).with('Counter_2', 2)
          expect(mock_datadog).to receive(:distribution).with('Distribution_1', 10)
          expect(mock_datadog).to receive(:set).with('Set_1', 100)
          expect(mock_datadog).to receive(:gauge).with('Gauge_1', 100)

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end

      context 'processes_hashed_inputs with tags in correct format' do
        let(:datadog_payload) do
          {
            count: { 'Counter_1' => { value: 1 }, 'Counter_2' => { value: 2, tags: ['test']} },
            distribution: { 'Distribution_1' => { value: 10, tags: ['test']} },
            set: { 'Set_1' => { value: 100, tags: ['test'] } },
            gauge: { 'Gauge_1' => { value: 100, tags: ['test'] } }
          }
        end

        it 'processes each hash keyset as a metric iteration' do
          expect(mock_datadog).to receive(:count).with('Counter_1', 1, {})
          expect(mock_datadog).to receive(:count).with('Counter_2', 2, tags: ['test'])
          expect(mock_datadog).to receive(:distribution).with('Distribution_1', 10, tags: ['test'])
          expect(mock_datadog).to receive(:set).with('Set_1', 100, tags: ['test'])
          expect(mock_datadog).to receive(:gauge).with('Gauge_1', 100, tags: ['test'])

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end

      context 'processes_hashed_inputs with tags as hash' do
        let(:datadog_payload) do
          {
            count: {
              'Counter_1' => { value: 1 },
              'Counter_2' => { value: 2, tags: { test: 'value' } }
            },
            distribution: { 'Distribution_1' => { value: 10, tags: { test: 'value' } } },
            set: { 'Set_1' => { value: 100, tags: { test: 'value' } } },
            gauge: { 'Gauge_1' => { value: 100, tags: { test: 'value' } } }
          }
        end

        it 'processes each hash keyset as a metric iteration' do
          expect(mock_datadog).to receive(:count).with('Counter_1', 1, {})
          expect(mock_datadog).to receive(:count).with('Counter_2', 2, tags: ['test|value'])
          expect(mock_datadog).to receive(:distribution).with('Distribution_1', 10, tags: ['test|value'])
          expect(mock_datadog).to receive(:set).with('Set_1', 100, tags: ['test|value'])
          expect(mock_datadog).to receive(:gauge).with('Gauge_1', 100, tags: ['test|value'])

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end

      context 'skip_processing_empty_datadog_args' do
        let(:datadog_payload) { {} }

        it 'skips any metric processing' do
          expect(mock_datadog).not_to receive(:count)
          expect(mock_datadog).not_to receive(:distribution)
          expect(mock_datadog).not_to receive(:histogram)
          expect(mock_datadog).not_to receive(:set)
          expect(mock_datadog).not_to receive(:gauge)

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end

      context 'processes_hashed_inputs with value and tag is nil' do
        let(:datadog_payload) do
          {
            count: { 'Counter_1' => { value: 1, tag: nil } }
          }
        end

        it 'processes each hash keyset as a metric iteration' do
          expect(mock_datadog).to receive(:count).with('Counter_1', 1, {})

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq true
        end
      end

      context 'processes_hashed_inputs with no value key' do
        let(:datadog_payload) do
          {
            count: { 'Counter_1' => { no_value: 1 } }
          }
        end

        it 'processes each hash keyset as a metric iteration' do
          expect(mock_datadog).not_to receive(:count).with('Counter_1', 1)

          result = subject.send(expected_call, datadog: datadog_payload)

          expect(result.success?).to eq false
          expect(result.error).to eq 'Datadog payload { Counter_1: {:no_value=>1} } invalid'
        end
      end

      context 'rejects_invalid_datadog_args' do
        INVALID_PAYLOADS.each do |datadog_value|
          context 'Invalid datadog top-level args' do
            let(:datadog_payload) { datadog_value }

            it 'rejects the payload when invalid datadog values are given' do
              expect(mock_datadog).not_to receive(:count)
              expect(mock_datadog).not_to receive(:distribution)
              expect(mock_datadog).not_to receive(:histogram)
              expect(mock_datadog).not_to receive(:set)
              expect(mock_datadog).not_to receive(:gauge)

              result = subject.send(expected_call, datadog: datadog_payload)

              expect(result.success?).to eq false
              expect(result.error).to eq 'Invalid datadog config'
            end
          end
        end
      end

      context 'rejects_invalid_metric_args' do
        EventTracer::DatadogLogger::SUPPORTED_METRICS.each do |metric|
          INVALID_PAYLOADS.each do |payload|
            context "Invalid metric values for #{metric}: #{payload}" do
              let(:datadog_payload) { { metric => payload } }

              it 'rejects the payload when invalid datadog values are given' do
                expect(mock_datadog).not_to receive(:count)
                expect(mock_datadog).not_to receive(:distribution)
                expect(mock_datadog).not_to receive(:histogram)
                expect(mock_datadog).not_to receive(:set)
                expect(mock_datadog).not_to receive(:gauge)

                result = subject.send(expected_call, datadog: datadog_payload)

                expect(result.success?).to eq false
                expect(result.error).to eq "Datadog metric #{metric} invalid"
              end
            end
          end
        end
      end
    end
  end
end
