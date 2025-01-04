# frozen_string_literal: true

module Regent
  module Engine
    class Base
      def initialize(context, llm, toolchain, session, max_iterations)
        @context = context
        @llm = llm
        @toolchain = toolchain
        @session = session
        @max_iterations = max_iterations
      end

      attr_reader :context, :llm, :toolchain, :session, :max_iterations

      private

      # Run reasoning block within this method to ensure that it
      # will not run more than max_iterations times.
      def with_max_iterations
        max_iterations.times do
          yield
        end

        error_answer("Max iterations reached without finding an answer.")
      end

      # Make a call to LLM and return the response.
      def llm_call_response(args)
        session.exec(Span::Type::LLM_CALL, type: llm.model, message: session.messages.last[:content]) do
          result = llm.invoke(session.messages, **args)

          session.current_span.set_meta("#{result.input_tokens} → #{result.output_tokens} tokens")
          result.content
        end
      end

      # Make a call to a tool and return the response.
      def tool_call_response(tool, arguments)
        session.exec(Span::Type::TOOL_EXECUTION, { type: tool.name, message: arguments }) do
          tool.execute(*arguments)
        end
      end

      # Find a tool in the toolchain by name and return it.
      def find_tool(tool_name)
        tool = toolchain.find(tool_name)
        return tool if tool

        session.exec(Span::Type::ANSWER, type: :failure, message: "No matching tool found for: #{tool_name}")
      end

      # Complete a session with a success answer
      def success_answer(content)
        session.exec(Span::Type::ANSWER, top_level: true,type: :success, message: content, duration: session.duration.round(2)) { content }
      end

      # Complete a session with an error answer
      def error_answer(content)
        session.exec(Span::Type::ANSWER, top_level: true, type: :failure, message: content, duration: session.duration.round(2)) { content }
      end
    end
  end
end
