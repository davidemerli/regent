# frozen_string_literal: true

module Regent
  class LLM
    class Gemini < Base
      ENV_KEY = "GEMINI_API_KEY"

      depends_on "gemini-ai"

      def invoke(messages, **args)
        response = client.generate_content({ contents: format_messages(messages) })
        format_response(response)
      end

      private

      def client
        @client ||= ::Gemini.new(
          credentials: { service: 'generative-language-api', api_key: api_key },
          options: { model: options[:model] }
        )
      end

      def format_messages(messages)
        messages.map do |message|
          { role: message[:role], parts: [{ text: message[:content] }] }
        end
      end

      def format_response(response)
       Response.new(
          content: response.dig("candidates", 0, "content", "parts", 0, "text").strip,
          model: options[:model],
          usage: Usage.new(
            input_tokens: response.dig("usageMetadata", "promptTokenCount"),
            output_tokens: response.dig("usageMetadata", "candidatesTokenCount")
          )
        )
      end
    end
  end
end
