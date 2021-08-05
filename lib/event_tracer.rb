require 'event_tracer/version'
require 'event_tracer/log_result'
require 'pry'

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
      send_log_messages(
        log_type,
        (selected_loggers(loggers) || @loggers),
        args
      )
    end
  end

  private

    def self.send_log_messages(log_type, loggers, args)
      result = Result.new

      loggers.each do |code, logger|
        begin
          if args[:action] && args[:message]
            result.record code, logger.send(log_type, **args)
          else
            result.record code, LogResult.new(false, 'Fields action & message need to be populated')
          end
        rescue Exception => e
          result.record code, LogResult.new(false, e.message)
        end
      end

      result
    end

    def self.selected_loggers(logger_codes)
      return unless logger_codes.is_a?(Array)
      return if logger_codes.detect { |code| !code.is_a?(Symbol) }

      selected_codes = logger_codes.uniq & registered_logger_codes

      return if selected_codes.empty?
      @loggers.select { |code, _logger| selected_codes.include?(code) }
    end

    def self.registered_logger_codes
      @loggers.keys
    end

    class Result
      attr_reader :records

      def initialize
        @records = {}
      end

      def record(logger_code, outcome)
        records[logger_code] = outcome
      end
    end

end

project_root = File.dirname(File.absolute_path(__FILE__))
Dir.glob("#{project_root}/event_tracer/*") {|file| require file}
