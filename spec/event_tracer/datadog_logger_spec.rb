require 'spec_helper'
require 'climate_control'

describe EventTracer::DatadogLogger do

  self::INVALID_METRIC_TYPES = [
    nil,
    Object.new,
    10
  ].freeze

  self::NON_WHITELISTED_METRIC_TYPES = [
    :invalid_payload,
    :add_distribution_value,
    'increment_counter',
    'set_gauge'
  ]

  let(:allowed_tags) { [] }
  let(:mock_datadog) { MockDatadog.new }

  subject { described_class.new(mock_datadog, allowed_tags: allowed_tags) }

  shared_examples_for 'skip_processing_empty_datadog_args' do
    it 'skips any metric processing' do
      expect(mock_datadog).not_to receive(:counter)
      expect(mock_datadog).not_to receive(:distribution)
      expect(mock_datadog).not_to receive(:gauge)
      expect(mock_datadog).not_to receive(:set)
      expect(mock_datadog).not_to receive(:histogram)

      result = subject.send(expected_call, metrics: {})

      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  shared_examples_for "skip_logging_non_whitelisted_metric_types" do
    self::NON_WHITELISTED_METRIC_TYPES.each do |type|
      context "Invalid metric values for #{type} type" do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: { metric_1: { type: type, value: 1 } },
            tenant_id: 'any_tenant',
            other_data: 'other_data'
          }
        end

        it 'skip perform logging' do
          expect(mock_datadog).not_to receive(:counter)
          expect(mock_datadog).not_to receive(:distribution)
          expect(mock_datadog).not_to receive(:gauge)
          expect(mock_datadog).not_to receive(:set)
          expect(mock_datadog).not_to receive(:histogram)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end
    end
  end

  shared_examples_for 'rejects_invalid_datadog_metric_types' do
    self::INVALID_METRIC_TYPES.each do |type|
      context "Invalid appsignal top-level args" do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: { metric_1: { type: type, value: 1 } },
            tenant_id: 'any_tenant',
            other_data: 'other_data'
          }
        end

        it 'raise error when invalid metric types are given' do
          expect(mock_datadog).not_to receive(:counter)
          expect(mock_datadog).not_to receive(:distribution)
          expect(mock_datadog).not_to receive(:gauge)
          expect(mock_datadog).not_to receive(:set)
          expect(mock_datadog).not_to receive(:histogram)

          expect { subject.send(expected_call, **params) }.to raise_error(NoMethodError)
        end
      end
    end
  end

  shared_examples_for 'processes_array_inputs' do
    let(:allowed_tags) { [:tenant_id] }
    let(:params) do
      {
        message: 'this is a message',
        action: 'some action',
        metrics: metrics,
        tenant_id: 'any_tenant',
        other_data: 'other_data'
      }
    end
    let(:metrics) { [:metric_1, :metric_2, :metric_3] }
    let(:expected_tags) { ['tenant_id:any_tenant', 'environment:development'] }

    it 'processes each hash keyset as a metric iteration' do
      ClimateControl.modify APP_ENV: 'development' do
        expect(mock_datadog).to receive(:count).with(:metric_1, 1, tags: expected_tags)
        expect(mock_datadog).to receive(:count).with(:metric_2, 1, tags: expected_tags)
        expect(mock_datadog).to receive(:count).with(:metric_3, 1, tags: expected_tags)

        result = subject.send(expected_call, **params)

        expect(result.success?).to eq true
        expect(result.error).to eq nil
      end
    end
  end

  shared_examples_for 'processes_hashed_inputs' do
    let(:allowed_tags) { [:tenant_id, :app] }
    let(:params) do
      {
        message: 'this is a message',
        action: 'some action',
        metrics: metrics,
        tenant_id: 'any_tenant',
        other_data: 'other_data',
        app: 'vma'
      }
    end
    let(:metrics) do
      {
        metric_1: { type: :gauge, value: 100 },
        metric_2: { 'type' => :counter, 'value' => 1 },
        metric_3: { type: :distribution, value: 10 },
        metric_4: { type: :set, value: 150 },
        metric_5: { type: :set, value: 50 }
      }
    end
    let(:expected_tags) { ['tenant_id:any_tenant', 'app:vma', 'environment:development'] }

    it 'processes each hash keyset as a metric iteration' do
      ClimateControl.modify APP_ENV: 'development' do
        expect(mock_datadog).to receive(:gauge).with(:metric_1, 100, tags: expected_tags)
        expect(mock_datadog).to receive(:count).with(:metric_2, 1, tags: expected_tags)
        expect(mock_datadog).to receive(:distribution).with(:metric_3, 10, tags: expected_tags)
        expect(mock_datadog).to receive(:set).with(:metric_4, 150, tags: expected_tags)
        expect(mock_datadog).to receive(:set).with(:metric_5, 50, tags: expected_tags)

        result = subject.send(expected_call, **params)

        expect(result.success?).to eq true
        expect(result.error).to eq nil
      end
    end

    context 'when tags is empty' do
      let(:allowed_tags) { [] }
      let(:expected_tags) { ['environment:development'] }
      it 'processes each hash keyset as a metric iteration' do
        ClimateControl.modify APP_ENV: 'development' do
          expect(mock_datadog).to receive(:gauge).with(:metric_1, 100, tags: expected_tags)
          expect(mock_datadog).to receive(:count).with(:metric_2, 1, tags: expected_tags)
          expect(mock_datadog).to receive(:distribution).with(:metric_3, 10, tags: expected_tags)
          expect(mock_datadog).to receive(:set).with(:metric_4, 150, tags: expected_tags)
          expect(mock_datadog).to receive(:set).with(:metric_5, 50, tags: expected_tags)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'skip_processing_empty_datadog_args'
      it_behaves_like 'skip_logging_non_whitelisted_metric_types'
      it_behaves_like 'rejects_invalid_datadog_metric_types'
      it_behaves_like 'processes_array_inputs'
      it_behaves_like 'processes_hashed_inputs'
    end
  end

  describe '#allowed_tags' do
    let(:allowed_tags) { ['random'] }
    let(:logger) { described_class.new(mock_datadog, allowed_tags: allowed_tags) }
    subject { logger.allowed_tags }

    it { is_expected.to eq allowed_tags }
    it { is_expected.to be_frozen }
  end
end
