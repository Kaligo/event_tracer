module EventTracer
  class ErrorWithPayload < StandardError
    attr_reader :payload

    def initialize(error, payload)
      super(error)
      @payload = payload
    end
  end
end
