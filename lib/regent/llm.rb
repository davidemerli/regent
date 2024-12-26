# frozen_string_literal: true

module Regent
  class LLM
    PROVIDER_PATTERNS = {
      OpenAI: /^gpt-/,
      Gemini: /^gemini-/,
      Anthropic: /^claude-/
    }.freeze

    def initialize(model:, **options)
      @model = model
      @options = options
    end

    def invoke(messages)
      response = provider.invoke( messages, **options)
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
      Regent::LLM.const_get(provider_class).new(**options.merge(model: model))
    end
  end
end
