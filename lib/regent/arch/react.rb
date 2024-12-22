module Regent
  module Arch
    class React
      ANSWER_SEQUENCE = "Answer:".freeze
      ACTION_SEQUENCE = "Action:".freeze
      OBSERVATION_SEQUENCE = "Observation:".freeze
      STOP_SEQUENCE = "PAUSE".freeze

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


      def initialize(tools, session, max_iterations)
        @tools = tools
        @session = session
        @max_iterations = max_iterations
      end

      attr_reader :tools, :session, :max_iterations

      def reason(task)
         session.messages = [
          {role: :system, content: SYSTEM_PROMPT % { tools: tool_names }},
          {role: :user, content: task}
        ]

        max_iterations.times do |i|
          content = session.continue(Span::Type::LLM_CALL, { messages: session.messages, params: { stop: [STOP_SEQUENCE] }})

          session.messages << {role: :assistant, content: content }

          return success_answer(content.split(ANSWER_SEQUENCE)[1].strip) if content.include?(ANSWER_SEQUENCE)

          if content.include?(ACTION_SEQUENCE)
            tool, argument = lookup_tool(content)

            return session.complete unless tool

            result = session.continue(Span::Type::TOOL_EXECUTION, { tool: tool, argument: argument })
            session.messages << {role: :user, content: "#{OBSERVATION_SEQUENCE} #{result}"}
          end
        end

        error_answer("Max iterations reached without finding an answer.")
      end

      private

      def success_answer(content)
        session.complete(Span::Type::ANSWER, { type: :success, content: content })
      end

      def error_answer(content)
        session.complete(Span::Type::ANSWER, { type: :error, content: content })
      end

      def tool_names
        tools.map(&:name).join(", ")
      end

      def lookup_tool(content)
        tool_name, argument = parse_tool_signature(content)
        tool = @tools.find { |tool| tool.name.downcase == tool_name.downcase }
        session.continue(Span::Type::ANSWER, { type: :error, content: "No matching tool found for: #{tool_name}" }) unless tool

        [tool, argument]
      end

      def parse_tool_signature(content)
        action = content.split(ACTION_SEQUENCE)[1]&.strip
        return [nil, nil] unless action

        parts = action.split('|', 2).map(&:strip)
        tool_name = parts[0]
        argument = parts[1]

        # Handle cases where argument is nil, empty, or only whitespace
        argument = nil if argument.nil? || argument.empty?

        [tool_name, argument]
      rescue
        [nil, nil]
      end
    end
  end
end
