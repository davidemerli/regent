# frozen_string_literal: true

module Regent
  class LLM
    class OpenRouter < Base
      ENV_KEY = "OPEN_ROUTER_API_KEY"

      depends_on "open_router"

      def invoke(messages, **args)
        response = client.complete(
          messages,
          model: model,
          extras: {
            temperature: args[:temperature] || 0.0,
            stop: args[:stop] || [],
            **args
          }
        )
        result(
          model: model,
          content: response.dig("choices", 0, "message", "content"),
          input_tokens: response.dig("usage", "prompt_tokens"),
          output_tokens: response.dig("usage", "completion_tokens")
        )
      end

      private

      def client
        @client ||= ::OpenRouter::Client.new access_token: api_key
      end
    end
  end
end
