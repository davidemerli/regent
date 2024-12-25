# frozen_string_literal: true

module Regent
  class Span
    include Concerns::Identifiable
    include Concerns::Durationable

    module Type
      INPUT = 'INPUT'.freeze
      LLM_CALL = 'LLM'.freeze
      TOOL_EXECUTION = 'TOOL'.freeze
      MEMORY_ACCESS = 'MEMO'.freeze
      ANSWER = 'ANSWER'.freeze

      def self.all
        constants.map { |c| const_get(c) }
      end

      def self.valid?(type)
        all.include?(type)
      end
    end

    # @param type [String] The type of span (must be one of Type.all)
    # @param arguments [Hash] Arguments for the span
    # @param logger [Logger] Logger instance
    def initialize(type:, arguments:, logger: Logger.new)
      super()

      validate_type!(type)

      @logger = logger
      @type = type
      @arguments = arguments
      @meta = nil
      @output = nil
    end

    attr_reader :name, :arguments, :output, :type, :start_time, :end_time

    # @raise [ArgumentError] if block is not given
    # @return [String] The output of the span
    def run
      raise ArgumentError, "Block is required" unless block_given?

      @output = log_operation do
        yield
      rescue StandardError => e
        logger.error(label: type, error: e.message, **arguments)
        raise
      end
    end

    # @return [Boolean] Whether the span is currently running
    def running?
      @start_time && @end_time.nil?
    end

    # @return [Boolean] Whether the span is completed
    def completed?
      @start_time && @end_time
    end

    # @param value [String] The meta value to set
    def set_meta(value)
      @meta = value.freeze
    end

    private

    attr_reader :logger, :meta

    def validate_type!(type)
      raise InvalidSpanType, "Invalid span type: #{type}" unless Type.valid?(type)
    end

    def log_operation(&block)
      @start_time = Time.now
      logger.start(label: type, **arguments)

      result = yield

      @end_time = Time.now
      logger.success(label: type, **({ duration: duration.round(2), meta: meta }.merge(arguments)))

      result
    end
  end
end
