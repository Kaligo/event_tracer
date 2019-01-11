module EventTracer
  class LogResult < Struct.new(:success?, :error)
  end
end
