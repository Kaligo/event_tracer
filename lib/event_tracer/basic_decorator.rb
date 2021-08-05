require 'delegate'

module EventTracer
  class BasicDecorator < Delegator

    def initialize(decoratee)
      super
      @delegate_sd_obj = @decoratee = decoratee
    end

    def __getobj__
      @delegate_sd_obj
    end

    def __setobj__(obj)
      @delegate_sd_obj = obj
    end

    def valid_args?(metrics)
      metrics && (metrics.is_a?(Hash) || metrics.is_a?(Array))
    end

    def success_result
      LogResult.new(true)
    end

    def fail_result(message)
      LogResult.new(false, message)
    end

  end
end
