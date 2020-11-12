class MockDatadog < Struct.new(:_)
  def increment(*_args)
    'increment'
  end

  def distribution(*_args)
    'distribution'
  end

  def set(*_args)
    'set'
  end

  def gauge(*_args)
    'gauge'
  end

  def histogram(*_args)
    'histogram'
  end
end
