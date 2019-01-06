require "event_tracer/version"

module EventTracer

  LOG_TYPES ||= %i(info warn error)

  @loggers = {}

  def self.register(code, logger)
    @loggers[code] = logger
  end

  def self.find(code)
    @loggers[code]
  end

  LOG_TYPES.each do |log_type|
    define_singleton_method log_type do |loggers: nil, **args|
      begin
        (selected_loggers(loggers) || @loggers).each do |_code, logger|
          logger.send(log_type, **args)
        end
        true
      rescue Exception => e
        p e.message
        false
      end
    end
  end

  private

    def self.selected_loggers(logger_codes)
      return unless logger_codes.is_a?(Array)
      return if logger_codes.detect { |code| !code.is_a?(Symbol) }

      selected_codes = logger_codes.uniq & @loggers.keys

      return if selected_codes.empty?
      @loggers.select { |code, _logger| selected_codes.include?(code) }
    end

end

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob("#{project_root}/event_tracer/*") {|file| require file}
