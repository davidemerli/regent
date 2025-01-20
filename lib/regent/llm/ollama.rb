# frozen_string_literal: true

module Regent
  class LLM
    class Ollama < Base
      # Default host for Ollama API.
      DEFAULT_HOST = "http://localhost:11434"

      def initialize(model:, host: nil, **options)
        @model = model
        @host = host || DEFAULT_HOST
        @options = options
      end

      def invoke(messages, **args)
        response = client.post("/api/chat", {
          model: model,
          messages: messages,
          stream: false
        })

        result(
          model: response.body.dig("model"),
          content: response.body.dig("message", "content").strip,
          input_tokens: nil,
          output_tokens: nil
        )
      end

      private

      attr_reader :host

      def client
        @client ||= Faraday.new(host) do |f|
          f.request :json
          f.response :json
          f.adapter :net_http
        end
      end

      def api_key_from_env
        nil
      end
    end
  end
end
