require 'securerandom'

module Regent
  DEFAULT_MAX_ITERATIONS = 10
  SYSTEM_PROMPT = <<~PROMPT
    You are assisstant reasoning step-by-step to solve complex problems.
    Your reasoning process happens in a loop of Though, Action, Observation.
    Thought - a description of your thoughts about the question.
    Action - pick a an action from available tools.
    Observation - is the result of running a tool.

    ## Available tools:
    %{tools}

    ## Example session
    Question: What is the weather in London today?
    Thought: I need to get the wether in London
    Action: weather_tool | "London"
    PAUSE

    You will have a response with Observation:
    Observation: It is 32 degress and Sunny

    ... (this Thought/Action/Observation can repeat N times)

    Thought: I know the final answer
    Answer: It is 32 degress and Sunny in London
  PROMPT

  class Agent
    ANSWER_SEQUENCE = "Answer:".freeze
    ACTION_SEQUENCE = "Action:".freeze
    OBSERVATION_SEQUENCE = "Observation:".freeze
    STOP_SEQUENCE = "PAUSE".freeze

    def initialize(llm = nil, tools = [], options = {})
      @id = SecureRandom.uuid
      @llm = llm
      @tools = tools
      @messages = []
      @max_iterations = options[:max_iterations] || DEFAULT_MAX_ITERATIONS
    end

    attr_reader :session, :llm, :tools

    def execute(task)
      @session = Session.new(self)
      reason(task)
    end

    def running?
      session.running?
    end

    private

    attr_reader :max_iterations, :messages

    def tool_names
      tools.map(&:name).join(", ")
    end

    def reason(task)
      session.start

      @messages = [
        {role: :system, content: SYSTEM_PROMPT % { tools: tool_names }},
        {role: :user, content: task}
      ]

      max_iterations.times do |i|
        content = session.continue(Span::Type::LLM_CALL, { messages: @messages, params: { stop: [STOP_SEQUENCE] }})

        @messages << {role: :assistant, content: content }

        return success_answer(content.split(ANSWER_SEQUENCE)[1].strip) if content.include?(ANSWER_SEQUENCE)

        if content.include?(ACTION_SEQUENCE)
          tool, argument = lookup_tool(content)

          return session.complete unless tool

          result = session.continue(Span::Type::TOOL_EXECUTION, { tool: tool, argument: argument })
          @messages << {role: :user, content: "#{OBSERVATION_SEQUENCE} #{result}"}
        end
      end

      error_answer("Max iterations reached without finding an answer.")
    end

    def success_answer(content)
      session.complete(Span::Type::ANSWER, { type: :success, content: content })
    end

    def error_answer(content)
       session.complete(Span::Type::ANSWER, { type: :error, content: content })
    end

    def lookup_tool(content)
      tool_name, argument = parse_tool_signature(content)
      tool = @tools.find { |tool| tool.name.downcase == tool_name.downcase }
      session.continue(Span::Type::ANSWER, { type: :error, content: "No matching tool found for: #{tool_name}" }) unless tool

      [tool, argument]
    end

    def find_tool(tool_name)
      @tools.find { |tool| tool.name.downcase == tool_name.downcase }

    end

    def parse_tool_signature(content)
      action = content.split(ACTION_SEQUENCE)[1].strip
      tool_name, argument = action.split("|").map(&:strip)
      argument = nil if argument.empty?
      [tool_name, argument]
    end
  end
end
