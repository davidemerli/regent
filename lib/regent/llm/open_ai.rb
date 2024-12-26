# frozen_string_literal: true

module Regent
  class LLM
    class OpenAI < Base

      def invoke(messages, **options)
        response = client.chat(messages: format_messages(messages), **options)
        format_response(response)
      end

      private

      def client
        @client ||= ::Langchain::LLM::OpenAI.new(api_key: api_key)
      end

      def api_key_from_env
        ENV.fetch("OPENAI_API_KEY") do
          raise APIKeyNotFoundError, "API key not found. Make sure to set OPENAI_API_KEY environment variable."
        end
      end
    end
  end
end
