require 'spec_helper'

describe EventTracer::PrometheusLogger do
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
  let(:default_tags) { { environment: 'development' } }
  let(:prometheus) { Prometheus::Client.registry }
  let(:raise_if_missing) { true }

  subject do
    described_class.new(
      prometheus,
      allowed_tags: allowed_tags,
      default_tags: default_tags,
      raise_if_missing: raise_if_missing
    )
  end

  shared_examples_for 'skip_processing_empty_args' do
    it 'skips any metric processing' do
      expect(prometheus).not_to receive(:counter)
      expect(prometheus).not_to receive(:gauge)

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
          expect(prometheus).not_to receive(:counter)
          expect(prometheus).not_to receive(:gauge)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end
    end
  end

  shared_examples_for 'rejects_invalid_metric_types' do
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
          expect(prometheus).not_to receive(:counter)
          expect(prometheus).not_to receive(:gauge)

          expect { subject.send(expected_call, **params) }.to raise_error(NoMethodError)
        end
      end
    end
  end

  context 'invalid input' do
    EventTracer::LOG_TYPES.each do |log_type|
      context "Log type: #{log_type}" do
        let(:expected_call) { log_type }

        it_behaves_like 'skip_processing_empty_args'
        it_behaves_like 'skip_logging_non_whitelisted_metric_types'
        it_behaves_like 'rejects_invalid_metric_types'
      end
    end
  end

  context 'when raise_if_missing is true' do
    let(:allowed_tags) { [:tenant_id, :app] }
    EventTracer::LOG_TYPES.each do |log_type|
      context "Log type: #{log_type}" do
        let(:expected_call) { log_type }
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: ['NewMetric'],
            tenant_id: 'any_tenant',
            other_data: 'other_data',
            app: 'vma'
          }
        end

        context 'when metric is not registered' do
          it 'raises the error' do
            expect { subject.send(log_type, **params) }.to raise_error('Metric NewMetric not registered')
          end
        end

        context 'when metric is already registered' do
          let(:expected_values_1) do
            {
              {
                environment: 'development',
                tenant_id: 'any_tenant',
                app: 'vma'
              } => 1.0
            }
          end

          before do
            prometheus.counter(:NewMetric, docstring: 'A counter for NewMetric', labels: [:tenant_id, :app, :environment])
          end

          after do
            prometheus.unregister(:NewMetric)
          end

          it 'collects metric' do
            result = subject.send(expected_call, **params)

            expect(result.success?).to eq true
            expect(result.error).to eq nil

            metric = prometheus.get(:NewMetric)
            expect(metric.name).to eq(:NewMetric)
            expect(metric.type).to eq(:counter)
            expect(metric.labels).to eq([:tenant_id, :app, :environment])
            expect(metric.values).to eq(expected_values_1)
          end
        end
      end
    end
  end

  context 'when raise_if_missing is false' do
    let(:raise_if_missing) { false }

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
      let(:metrics) { [:metric_1, :metric_2] }
      let(:expected_labels) do
        { environment: 'development', tenant_id: 'any_tenant' }
      end
      let(:expected_values_1) { { expected_labels => 1.0 } }
      let(:expected_values_2) { { expected_labels => 1.0 } }

      before do
        prometheus.unregister(:metric_1)
        prometheus.unregister(:metric_2)
      end

      it 'processes each hash keyset as a metric iteration' do
        result = subject.send(expected_call, **params)

        expect(result.success?).to eq true
        expect(result.error).to eq nil

        metric = prometheus.get(:metric_1)
        expect(metric.name).to eq(:metric_1)
        expect(metric.type).to eq(:counter)
        expect(metric.labels).to eq([:tenant_id, :environment])
        expect(metric.values).to eq(expected_values_1)

        metric = prometheus.get(:metric_2)
        expect(metric.name).to eq(:metric_2)
        expect(metric.type).to eq(:counter)
        expect(metric.labels).to eq([:tenant_id, :environment])
        expect(metric.values).to eq(expected_values_2)
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
          metric_2: { 'type' => :counter, 'value' => 3 }
        }
      end
      let(:expected_values_1) { { expected_labels => 100.0 } }
      let(:expected_values_2) { { expected_labels => 3.0 } }

      let(:expected_labels) do
        { environment: 'development', tenant_id: 'any_tenant', app: 'vma' }
      end

      before do
        prometheus.unregister(:metric_1)
        prometheus.unregister(:metric_2)
      end

      it 'processes each hash keyset as a metric iteration' do
        result = subject.send(expected_call, **params)

        expect(result.success?).to eq true
        expect(result.error).to eq nil

        metric = prometheus.get(:metric_1)
        expect(metric.name).to eq(:metric_1)
        expect(metric.type).to eq(:gauge)
        expect(metric.labels).to eq([:tenant_id, :app, :environment])
        expect(metric.values).to eq(expected_values_1)

        metric = prometheus.get(:metric_2)
        expect(metric.name).to eq(:metric_2)
        expect(metric.type).to eq(:counter)
        expect(metric.labels).to eq([:tenant_id, :app, :environment])
        expect(metric.values).to eq(expected_values_2)
      end

      context 'when tags is empty' do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: metrics
          }
        end
        let(:expected_labels) do
          { environment: 'development', tenant_id: '', app: '' }
        end

        it 'processes each hash keyset as a metric iteration' do
          result = subject.send(expected_call, **params)
          expect(result.success?).to eq true
          expect(result.error).to eq nil

          metric = prometheus.get(:metric_1)
          expect(metric.name).to eq(:metric_1)
          expect(metric.type).to eq(:gauge)
          expect(metric.labels).to eq([:tenant_id, :app, :environment])
          expect(metric.values).to eq(expected_values_1)

          metric = prometheus.get(:metric_2)
          expect(metric.name).to eq(:metric_2)
          expect(metric.type).to eq(:counter)
          expect(metric.labels).to eq([:tenant_id, :app, :environment])
          expect(metric.values).to eq(expected_values_2)
        end
      end
    end

    shared_examples_for 'no_default_tags' do
      let(:allowed_tags) { [:tenant_id, :app] }
      let(:default_tags) { {} }
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
          metric_2: { 'type' => :counter, 'value' => 1 }
        }
      end
      let(:expected_values_1) { { expected_labels => 100.0 } }
      let(:expected_values_2) { { expected_labels => 1.0 } }
      let(:expected_labels) { { tenant_id: 'any_tenant', app: 'vma' } }

      before do
        prometheus.unregister(:metric_1)
        prometheus.unregister(:metric_2)
      end

      it 'sends tags correctly' do
        result = subject.send(expected_call, **params)

        expect(result.success?).to eq true
        expect(result.error).to eq nil

        metric = prometheus.get(:metric_1)
        expect(metric.name).to eq(:metric_1)
        expect(metric.type).to eq(:gauge)
        expect(metric.labels).to eq([:tenant_id, :app])
        expect(metric.values).to eq(expected_values_1)

        metric = prometheus.get(:metric_2)
        expect(metric.name).to eq(:metric_2)
        expect(metric.type).to eq(:counter)
        expect(metric.labels).to eq([:tenant_id, :app])
        expect(metric.values).to eq(expected_values_2)
      end
    end

    EventTracer::LOG_TYPES.each do |log_type|
      context "Log type: #{log_type}" do
        let(:expected_call) { log_type }

        it_behaves_like 'processes_array_inputs'
        it_behaves_like 'processes_hashed_inputs'
        it_behaves_like 'no_default_tags'
      end
    end

    describe '#allowed_tags' do
      let(:allowed_tags) { ['random'] }
      let(:logger) { described_class.new(prometheus, allowed_tags: allowed_tags) }

      subject { logger.allowed_tags }

      it { is_expected.to eq allowed_tags }
      it { is_expected.to be_frozen }
    end
  end
end
