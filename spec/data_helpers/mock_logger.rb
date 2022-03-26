class MockLogger < Struct.new(:_)
  def info(*_args); 'info'; end
  def error(*_args); 'error'; end
  def warn(*_args); 'warn'; end
  def debug(*_args); 'debug'; end
end
