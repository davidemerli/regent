# frozen_string_literal: true

module Regent
  module Engine
    class React
      SEQUENCES = {
        answer: "Answer:",
        action: "Action:",
        observation: "Observation:",
        stop: "PAUSE"
      }.freeze

      def initialize(llm, toolchain, session, max_iterations)
        @llm = llm
        @toolchain = toolchain
        @session = session
        @max_iterations = max_iterations
      end

      attr_reader :llm, :toolchain, :session, :max_iterations

      def reason(task)
        initialize_session(task)

        max_iterations.times do |i|
          content = get_llm_response
          session.add_message({role: :assistant, content: content })
          return extract_answer(content) if answer_present?(content)

          if action_present?(content)
            tool, argument = parse_action(content)
            return unless tool

            process_tool_execution(tool, argument)
          end
        end

        error_answer("Max iterations reached without finding an answer.")
      end

      private

      def initialize_session(task)
        session.add_message({role: :system, content: Regent::Engine::React::PromptTemplate.system_prompt(toolchain.to_s)})
        session.add_message({role: :user, content: task})
        session.exec(Span::Type::INPUT, message: task) { task }
      end

      def get_llm_response
        session.exec(Span::Type::LLM_CALL, type: llm.model, message: session.messages.last[:content]) do
          result = llm.invoke(session.messages, stop: [SEQUENCES[:stop]])

          # Relying on Langchain Response interface to get token counts and chat completion
          session.current_span.set_meta("#{result.usage.input_tokens} → #{result.usage.output_tokens} tokens")
          result.content
        end
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
        result = session.exec(Span::Type::TOOL_EXECUTION, { type: tool.name, message: argument }) do
          tool.call(argument)
        end

        session.add_message({ role: :user, content: "#{SEQUENCES[:observation]} #{result}" })
      end

      def answer_present?(content)
        content.include?(SEQUENCES[:answer])
      end

      def action_present?(content)
        content.include?(SEQUENCES[:action])
      end

      def success_answer(content)
        session.exec(Span::Type::ANSWER, type: :success, message: content, duration: session.duration.round(2)) { content }
      end

      def error_answer(content)
        session.exec(Span::Type::ANSWER, type: :failure, message: content, duration: session.duration.round(2)) { content }
      end

      def lookup_tool(content)
        tool_name, argument = parse_tool_signature(content)
        tool = toolchain.find(tool_name)

        unless tool
          session.exec(Span::Type::ANSWER, type: :failure, message: "No matching tool found for: #{tool_name}")
          return [nil, nil]
        end

        [tool, argument]
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
