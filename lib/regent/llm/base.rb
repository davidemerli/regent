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
      include Concerns::Dependable

      def initialize(**options)
        @options = options
        api_key.nil?

        super()
      end

      def invoke(messages, **args)
        provider.chat(messages: format_messages(messages), **args)
      end

      private

      attr_reader :options, :dependency

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

      def api_key_from_env
        ENV.fetch(self.class::ENV_KEY) do
          raise APIKeyNotFoundError, "API key not found. Make sure to set #{self.class::ENV_KEY} environment variable."
        end
      end
    end
  end
end
