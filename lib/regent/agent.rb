# frozen_string_literal: true

module Regent
  class Agent
    include Concerns::Identifiable
    include Concerns::Toolable

    DEFAULT_MAX_ITERATIONS = 10

    def initialize(context, model:, tools: [], engine: Regent::Engine::React, **options)
      super()

      @context = context
      @model = model.is_a?(Regent::LLM) ? model : Regent::LLM.new(model)
      @engine = engine
      @sessions = []
      @tools = build_toolchain(tools)
      @max_iterations = options[:max_iterations] || DEFAULT_MAX_ITERATIONS
    end

    attr_reader :context, :sessions, :model, :tools, :inline_tools

    def run(task)
      raise ArgumentError, "Task cannot be empty" if task.to_s.strip.empty?

      start_session
      reason(task)
    ensure
      complete_session
    end

    def running?
      session&.active? || false
    end

    def session
      @sessions.last
    end

    private

    def reason(task)
      engine.reason(task)
    end

    def start_session
      complete_session
      @sessions << Session.new
      session.start
    end

    def complete_session
      session&.complete if running?
    end

    def build_toolchain(tools)
      context = self

      toolchain = Toolchain.new(Array(tools))

      self.class.function_tools.each do |entry|
        toolchain.add(entry, context)
      end

      toolchain
    end

    def engine
      @engine.new(context, model, tools, session, @max_iterations)
    end
  end
end
