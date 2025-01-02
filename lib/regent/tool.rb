# frozen_string_literal: true

module Regent
  class ToolError < StandardError; end

  class Tool
    def initialize(name:, description:)
      @name = name
      @description = description
    end

    attr_reader :name, :description

    def call(argument)
      raise NotImplementedError, "Tool #{name} has not implemented the execute method"
    end

    def execute(argument)
      call(argument)
    rescue NotImplementedError, StandardError => e
      raise ToolError, e.message
    end

    def to_s
      "#{name} - #{description}"
    end
  end
end
