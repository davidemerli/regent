# frozen_string_literal: true

module Regent
  class LLM
    class Anthropic < Base

      def invoke(messages, **options)
        response = client.chat(messages: format_messages(messages), **options)
        format_response(response)
      end

      private

      def client
        @client ||= ::Langchain::LLM::Anthropic.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
      end

      def api_key_from_env
        ENV.fetch("ANTHROPIC_API_KEY") do
          raise APIKeyNotFoundError, "API key not found. Make sure to set ANTHROPIC_API_KEY environment variable."
        end
      end
    end
  end
end
