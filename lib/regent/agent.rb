module Regent
  class Agent
    include Concerns::Identifiable

    DEFAULT_MAX_ITERATIONS = 10

    def initialize(llm = nil, tools = [], options = {})
      super()

      @llm = llm
      @tools = tools
      @sessions = []
      @max_iterations = options[:max_iterations] || DEFAULT_MAX_ITERATIONS
    end

    attr_reader :sessions, :llm, :tools

    def execute(task)
      start_session
      react.reason(task)
    end

    def running?
      session.running?
    end

    def session
      @sessions.last
    end

    private

    def start_session
      @sessions << Session.new(self)
      session.start
    end

    def react
      Regent::Arch::React.new(tools, session, @max_iterations)
    end
  end
end
