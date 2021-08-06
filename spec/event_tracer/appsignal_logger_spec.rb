require 'spec_helper'

describe EventTracer::AppsignalLogger do

  INVALID_METRIC_TYPES = [
    nil,
    Object.new,
    10
  ].freeze

  NON_WHITELISTED_METRIC_TYPES = [
    :invalid_payload,
    :count,
    'set',
    'histogram'
  ]

  let(:allowed_tags) { [] }
  let(:mock_appsignal) { MockAppsignal.new }

  subject { EventTracer::AppsignalLogger.new(mock_appsignal, allowed_tags: allowed_tags) }

  shared_examples_for 'skip_processing_empty_appsignal_args' do
    it 'skips any metric processing' do
      expect(mock_appsignal).not_to receive(:increment_counter)
      expect(mock_appsignal).not_to receive(:add_distribution_value)
      expect(mock_appsignal).not_to receive(:set_gauge)

      result = subject.send(expected_call, metrics: {})

      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  shared_examples_for 'skip_logging_non_whitelisted_metric_types' do
    NON_WHITELISTED_METRIC_TYPES.each do |type|
      context "non whitelisted metric types" do
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
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq true
          expect(result.error).to eq nil
        end
      end
    end
  end

  shared_examples_for "rejects_invalid_appsignal_metric_type" do
    INVALID_METRIC_TYPES.each do |type|
      context "Invalid metric values for #{type} type" do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: { metric_1: { type: type } },
            tenant_id: 'any_tenant',
            other_data: 'other_data'
          }
        end

        it 'raise error when invalid metric types are given' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)

          expect { subject.send(expected_call, **params) }.to raise_error(NoMethodError)
        end
      end
    end
  end

  shared_examples_for 'processes_array_inputs' do
    let(:allowed_tags) { [:tenant_id, :app] }
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

    it 'processes each hash keyset as a metric iteration' do
      expect(mock_appsignal).to receive(:increment_counter).with(:metric_1, 1, {:tenant_id=>"any_tenant"})
      expect(mock_appsignal).to receive(:increment_counter).with(:metric_2, 1, {:tenant_id=>"any_tenant"})
      expect(mock_appsignal).to receive(:increment_counter).with(:metric_3, 1, {:tenant_id=>"any_tenant"})

      result = subject.send(expected_call, **params)

      expect(result.success?).to eq true
      expect(result.error).to eq nil
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
        other_data: 'other_data'
      }
    end
    let(:metrics) do
      {
        metric_1: { type: :gauge, value: 100 },
        metric_2: { type: :counter, value: 1 },
        metric_3: { type: :distribution, value: 10 }
      }
    end

    it 'processes each hash keyset as a metric iteration' do
      expect(mock_appsignal).to receive(:set_gauge).with(:metric_1, 100, { tenant_id: 'any_tenant' })
      expect(mock_appsignal).to receive(:increment_counter).with(:metric_2, 1, { tenant_id: 'any_tenant' })
      expect(mock_appsignal).to receive(:add_distribution_value).with(:metric_3, 10, tenant_id: 'any_tenant')

      result = subject.send(expected_call, **params)

      expect(result.success?).to eq true
      expect(result.error).to eq nil
    end
  end

  EventTracer::LOG_TYPES.each do |log_type|
    context "Log type: #{log_type}" do
      let(:expected_call) { log_type }

      it_behaves_like 'skip_processing_empty_appsignal_args'
      it_behaves_like 'skip_logging_non_whitelisted_metric_types'
      it_behaves_like 'rejects_invalid_appsignal_metric_type'
      it_behaves_like 'processes_array_inputs'
      it_behaves_like 'processes_hashed_inputs'
    end
  end

end
