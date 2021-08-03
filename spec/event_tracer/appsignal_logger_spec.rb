require 'spec_helper'

describe EventTracer::AppsignalLogger do

  INVALID_PAYLOADS ||= [
    nil,
    Object.new,
    'string',
    10,
    :invalid_payload
  ].freeze

  let(:allowed_tags) { [:tenant_id] }
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

  shared_examples_for 'rejects_invalid_appsignal_args' do
    INVALID_PAYLOADS.each do |appsignal_value|
      context "Invalid appsignal top-level args" do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: appsignal_value,
            tenant_id: 'any_tenant',
            other_data: 'other_data'
          }
        end

        it 'rejects the payload when invalid appsignal values are given' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq false
          expect(result.error).to eq 'Invalid appsignal config'
        end
      end
    end
  end

  shared_examples_for "rejects_invalid_metric_args" do
    INVALID_PAYLOADS.each do |payload|
      context "Invalid metric values for #{payload} type" do
        let(:params) do
          {
            message: 'this is a message',
            action: 'some action',
            metrics: { metric_1: { type: payload } },
            tenant_id: 'any_tenant',
            other_data: 'other_data'
          }
        end

        it 'rejects the payload when invalid appsignal values are given' do
          expect(mock_appsignal).not_to receive(:increment_counter)
          expect(mock_appsignal).not_to receive(:add_distribution_value)
          expect(mock_appsignal).not_to receive(:set_gauge)

          result = subject.send(expected_call, **params)

          expect(result.success?).to eq false
          expect(result.error).to eq "Appsignal metric #{payload} invalid"
        end
      end
    end

    context 'with invalid tagging payload' do
      let(:params) do
        { metrics: { metric_1: { type: :counter, value: 10 } } }
      end

      it 'rejects the payload and return failure result' do
        expect(mock_appsignal).not_to receive(:increment_counter)
        expect(mock_appsignal).not_to receive(:add_distribution_value)
        expect(mock_appsignal).not_to receive(:set_gauge)

        result = subject.send(expected_call, **params)

        expect(result.success?).to eq false
        expect(result.error).to eq "Appsignal payload invalid tag #{allowed_tags}"
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

   subject { EventTracer::AppsignalLogger.new(mock_appsignal, allowed_tags: allowed_tags) }

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

    subject { EventTracer::AppsignalLogger.new(mock_appsignal, allowed_tags: allowed_tags) }

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
      it_behaves_like 'rejects_invalid_appsignal_args'
      it_behaves_like 'rejects_invalid_metric_args'
      it_behaves_like 'processes_array_inputs'
      it_behaves_like 'processes_hashed_inputs'
    end
  end

end
