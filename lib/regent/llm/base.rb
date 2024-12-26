# frozen_string_literal: true

module Regent
  class LLM
    class Response
      def initialize(content:, usage:, model:)
        @content = content
        @usage = usage
        @model = model
      end

      attr_reader :content, :usage, :model
    end

    class Usage
      def initialize(input_tokens:, output_tokens:)
        @input_tokens = input_tokens
        @output_tokens = output_tokens
      end

      attr_reader :input_tokens, :output_tokens
    end

    class Base
      def initialize(**options)
        @options = options
      end

      def invoke(messages, **options)
        provider.chat(messages: format_messages(messages), **options)
      end

      private

      attr_reader :options

      def format_messages(messages)
        messages
      end

      def format_response(response)
        Response.new(
          content: response.chat_completion,
          model: options[:model],
          usage: Usage.new(input_tokens: response.prompt_tokens, output_tokens: response.completion_tokens)
        )
      end

      def api_key
        @api_key ||= options[:api_key] || api_key_from_env
      end
    end
  end
end
