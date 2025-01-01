# frozen_string_literal: true

module Regent
  class LLM
    class Gemini < Base
      ENV_KEY = "GEMINI_API_KEY"
      SERVICE = "generative-language-api"

      depends_on "gemini-ai"

      def invoke(messages, **args)
        response = client.generate_content({ contents: format_messages(messages) })

        result(
          model: model,
          content: response.dig("candidates", 0, "content", "parts", 0, "text").strip,
          input_tokens: response.dig("usageMetadata", "promptTokenCount"),
          output_tokens: response.dig("usageMetadata", "candidatesTokenCount")
        )
      end

      def parse_error(error)
        JSON.parse(error.response.dig(:body)).dig("error", "message")
      end

      private

      def client
        @client ||= ::Gemini.new(
          credentials: { service: SERVICE, api_key: api_key },
          options: { model: model }
        )
      end

      def format_messages(messages)
        messages.map do |message|
          { role: message[:role].to_s == "system" ? "user" : message[:role], parts: [{ text: message[:content] }] }
        end
      end
    end
  end
end
