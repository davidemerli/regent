# frozen_string_literal: true

module Regent
  class Agent
    include Concerns::Identifiable

    DEFAULT_MAX_ITERATIONS = 10

    def initialize(llm:, tools: [], **options)
      super()

      @llm = llm
      @tools = Array(tools)
      @sessions = []
      @max_iterations = options[:max_iterations] || DEFAULT_MAX_ITERATIONS
    end

    attr_reader :sessions, :llm, :tools

    def execute(task)
      raise ArgumentError, "Task cannot be empty" if task.to_s.strip.empty?

      start_session
      react.reason(task)
    ensure
      session&.complete if running?
    end

    def running?
      session&.running? || false
    end

    def session
      @sessions.last
    end

    private

    def start_session
      session&.complete if running?
      @sessions << Session.new(self)
      session.start
    end

    def react
      Regent::Arch::React.new(tools, session, @max_iterations)
    end
  end
end
