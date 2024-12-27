# frozen_string_literal: true

module Regent
  class LLM
    class OpenAI < Base
      ENV_KEY = "OPENAI_API_KEY"

      depends_on "ruby-openai"

      def invoke(messages, **args)
        response = client.chat(parameters: {
          messages: format_messages(messages),
          model: options[:model],
          stop: args[:stop]
        })
        format_response(response)
      end

      private

      def client
        @client ||= ::OpenAI::Client.new(access_token: api_key)
      end

      def format_response(response)
        Response.new(
          content: response.dig("choices", 0, "message", "content"),
          model: options[:model],
          usage: Usage.new(
            input_tokens: response.dig("usage", "prompt_tokens"),
            output_tokens: response.dig("usage", "completion_tokens")
          )
        )
      end
    end
  end
end
