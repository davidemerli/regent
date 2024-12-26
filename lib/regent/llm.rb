# frozen_string_literal: true

module Regent
  class LLM
    PROVIDER_PATTERNS = {
      OpenAI: /^gpt-/,
      GoogleGemini: /^gemini-/,
      Anthropic: /^claude-/
    }.freeze

    class Response < Struct.new(:content, :usage); end
    class Usage < Struct.new(:input_tokens, :output_tokens); end

    def initialize(model:, **options)
      @model = model
      @options = options
    end

    def invoke(messages)
      response = provider.chat(messages: messages, **options)
      format_response(response)
    end

    private

    attr_reader :model, :options

    def provider
      provider_class = find_provider_class
      raise ProviderNotFoundError, "Provider for #{model} is not found" if provider_class.nil?

      @provider ||= create_provider(provider_class)
    end

    def find_provider_class
      PROVIDER_PATTERNS.find { |key, pattern| model.match?(pattern) }&.first
    end

    def create_provider(provider_class)
      ::Langchain::LLM.const_get(provider_class).new(
        api_key: fetch_api_key(provider_class),
        **options
      )
    end

    def fetch_api_key(provider_class)
      key = format_provider_key(provider_class)
      ENV.fetch("#{key}_API_KEY") do
        raise APIKeyNotFoundError, "API key not found for #{provider_class}"
      end
    end

    def format_response(response)
      Response.new(
        content: response.chat_completion,
        usage: Usage.new(input_tokens: response.prompt_tokens, output_tokens: response.completion_tokens)
      )
    end

    def format_provider_key(key)
      key.to_s
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .upcase
    end
  end
end
