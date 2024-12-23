# frozen_string_literal: true

module Regent
  module Arch
    class React
      SEQUENCES = {
        answer: "Answer:",
        action: "Action:",
        observation: "Observation:",
        stop: "PAUSE"
      }.freeze

      def initialize(tools, session, max_iterations)
        @tools = tools
        @session = session
        @max_iterations = max_iterations
      end

      attr_reader :tools, :session, :max_iterations

      def reason(task)
        initialize_session(task)

        max_iterations.times do |i|
          content = get_llm_response
          session.messages << {role: :assistant, content: content }

          return extract_answer(content) if answer_present?(content)

          if action_present?(content)
            tool, argument = parse_action(content)
            return session.complete unless tool

            process_tool_execution(tool, argument)
          end
        end

        error_answer("Max iterations reached without finding an answer.")
      end

      private

      def initialize_session(task)
        session.messages = [
          {role: :system, content: ReactPromptTemplate.system_prompt(tool_names)},
          {role: :user, content: task}
        ]
        session.continue(Span::Type::INPUT, { content: task })
      end

      def get_llm_response
        session.continue(
          Span::Type::LLM_CALL,
          {
            messages: session.messages,
            params: { stop: [SEQUENCES[:stop]] }
          }
        )
      end

      def extract_answer(content)
        answer = content.split(SEQUENCES[:answer])[1]&.strip
        success_answer(answer)
      end

      def parse_action(content)
        sanitized_content = content.gsub(SEQUENCES[:stop], "")
        lookup_tool(sanitized_content)
      end

      def process_tool_execution(tool, argument)
        result = session.continue(Span::Type::TOOL_EXECUTION, { tool: tool, argument: argument })
        session.messages << {
          role: :user,
          content: "#{SEQUENCES[:observation]} #{result}"
        }
      end

      def answer_present?(content)
        content.include?(SEQUENCES[:answer])
      end

      def action_present?(content)
        content.include?(SEQUENCES[:action])
      end

      def success_answer(content)
        session.complete(Span::Type::ANSWER, { type: :success, content: content })
      end

      def error_answer(content)
        session.complete(Span::Type::ANSWER, { type: :failure, content: content })
      end

      def tool_names
        tools.map do |tool|
          "#{tool.name} - #{tool.description}"
        end.join("\n")
      end

      def lookup_tool(content)
        tool_name, argument = parse_tool_signature(content)
        tool = find_matching_tool(tool_name)
        return [nil, nil] unless tool

        [tool, argument]
      end

      def find_matching_tool(tool_name)
        return nil unless tool_name

        tool = @tools.find { |t| t.name.downcase == tool_name.downcase }
        unless tool
          session.continue(
            Span::Type::ANSWER,
            { type: :failure, content: "No matching tool found for: #{tool_name}" }
          )
        end
        tool
      end

      def parse_tool_signature(content)
        action = content.split(SEQUENCES[:action])[1]&.strip
        return [nil, nil] unless action

        parts = action.split('|', 2).map(&:strip)
        tool_name = parts[0]
        argument = parts[1].gsub('"', '')

        # Handle cases where argument is nil, empty, or only whitespace
        argument = nil if argument.nil? || argument.empty?

        [tool_name, argument]
      rescue
        [nil, nil]
      end
    end
  end
end
