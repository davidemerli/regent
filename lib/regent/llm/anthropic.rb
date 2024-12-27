# frozen_string_literal: true

module Regent
  class LLM
    class Anthropic < Base
      MAX_TOKENS = 1000
      ENV_KEY = "ANTHROPIC_API_KEY"

      depends_on "anthropic"

      def invoke(messages, **args)
        response = client.messages(parameters: {
          messages: format_messages(messages),
          model: options[:model],
          stop_reason: args[:stop],
          max_tokens: MAX_TOKENS
        })
        format_response(response)
      end

      private

      def client
        @client ||= ::Anthropic::Client.new(access_token: api_key)
      end

      def format_response(response)
        Response.new(
          content: response.dig("content", 0, "text"),
          model: options[:model],
          usage: Usage.new(
            input_tokens: response.dig("usage", "input_tokens"),
            output_tokens: response.dig("usage", "output_tokens")
          )
        )
      end
    end
  end
end
