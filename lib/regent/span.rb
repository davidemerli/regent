module Regent
  class Span
    include Concerns::Identifiable

    module Type
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

    def initialize(session, type, arguments)
      super()

      @session = session
      @logger = Logger.new
      @type = type
      @arguments = arguments
      @status = :pending
      @output = nil
    end

    attr_reader :name, :arguments, :output, :type, :start_time, :end_time

    def execute
      @status = :running
      @start_time = Time.now
      @output = send(type, @arguments)
      @status = :completed
      @end_time = Time.now
      @output
    end

    def running?
      @status == :running
    end

    def completed?
      @status == :completed
    end

    def duration
      @end_time - @start_time
    end

    alias_method :inspect!, :inspect
    def inspect
      self.to_s
    end

    private

    attr_reader :logger, :session

    def llm_call(arguments)
      logger.log("[LLM]: Calling #{session.llm.defaults[:chat_model]}")
      response = session.llm.chat(
        messages: arguments[:messages],
        params: arguments[:params]
      )
      logger.log("[LLM]:")
      logger.success("Done")
      response.chat_completion
    end

    def tool_execution(arguments)
      logger.log("[TOOL]: Calling #{arguments[:tool].name}")
      result = arguments[:tool].call(arguments[:argument])
      logger.log("[TOOL]:")
      logger.success(result)

      return result
    end

    def memory_access(arguments)
      logger.log("[MEMORY]: Reading memory")
      # TODO: Implement memory access
    end

    def answer(arguments)
      logger.log("[ANSWER]:")

      if arguments[:type] == :success
        logger.success(arguments[:content])
      else
        logger.error(arguments[:content])
      end
      arguments[:content]
    end
  end
end
