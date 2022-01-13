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

    def success_result
      LogResult.new(true)
    end

    def fail_result(message)
      LogResult.new(false, message)
    end

    private

    attr_reader :decoratee
  end
end
