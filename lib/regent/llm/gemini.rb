# frozen_string_literal: true

module Regent
  class LLM
    class Gemini < Base
      def invoke(messages, **options)
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

      def api_key_from_env
        ENV.fetch("GEMINI_API_KEY") do
          raise APIKeyNotFoundError, "API key not found. Make sure to set GEMINI_API_KEY environment variable."
        end
      end
    end
  end
end
