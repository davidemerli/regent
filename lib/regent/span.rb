# frozen_string_literal: true

module Regent
  class Span
    include Concerns::Identifiable

    module Type
      INPUT = 'input'.freeze
      LLM_CALL = 'llm_call'.freeze
      TOOL_EXECUTION = 'tool_execution'.freeze
      MEMORY_ACCESS = 'memory_access'.freeze
      ANSWER = 'answer'.freeze

      def self.all
        constants.map { |c| const_get(c) }
      end

      def self.valid?(type)
        all.include?(type)
      end
    end

    def initialize(session:, type:, arguments:, logger: Logger.new)
      super()

      validate_type!(type)

      @session = session
      @logger = logger
      @type = type
      @arguments = arguments
      @meta = nil
      @status = :pending
      @output = nil
    end

    attr_reader :name, :arguments, :output, :type, :start_time, :end_time

    def execute
      with_status(:running) do
        @output = send(type, @arguments)
      end

      @output
    end

    def running?
      @status == :running
    end

    def completed?
      @status == :completed
    end

    def duration
      @end_time = Time.now if @end_time.nil?
      @end_time - @start_time
    end

    private

    attr_reader :logger, :session

    # Span type implementations
    def llm_call(arguments)
      log_operation(label: "LLM ", type: session.llm.defaults[:chat_model], message: arguments[:messages].last[:content]) do
        response = session.llm.chat(
          messages: arguments[:messages],
          params: arguments[:params]
        )

        @meta = "#{response.raw_response.dig("usage", "prompt_tokens")} → #{response.raw_response.dig("usage", "completion_tokens")} tokens"

        response.chat_completion
      end
    end

    def tool_execution(arguments)
      log_operation(label: "TOOL", type: arguments[:tool].name, message: arguments[:argument]) do
        arguments[:tool].call(arguments[:argument])
      end
    end

    def memory_access(arguments)
      log_operation(label: "MEMO", message: "Reading memory") do
        # TODO: Implement memory access
      end
    end

    def input(arguments)
      logger.success(label: "INPUT", message: arguments[:content], top_level: true)

      arguments[:content]
    end

    def answer(arguments)
      logger.success(
        label: "ANSWER",
        type: arguments[:type],
        message: arguments[:content],
        duration: session.duration.round(2),
        top_level: true
      )

      arguments[:content]
    end

    def validate_type!(type)
      raise InvalidSpanType, "Invalid span type: #{type}" unless Type.valid?(type)
    end

    def with_status(status)
      @status = status
      @start_time = Time.now if status == :running
      yield
      @status = :completed
      @end_time = Time.now
    end

    def log_operation(label:, type: nil, message:, **options)
      logger.start(label: label, type: type, message: message, **options)

      result = yield

      logger.success(label: label, type: type, message: message, duration: duration.round(2), meta: @meta, **options)
      result
    end
  end
end
