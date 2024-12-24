# frozen_string_literal: true

module Regent
  class Tool
    def initialize(name:, description:)
      @name = name
      @description = description
    end

    attr_reader :name, :description

    def call(argument)
      raise NotImplementedError, "Tool #{name} has not implemented the execute method"
    end

    def to_s
      "#{name} - #{description}"
    end
  end
end
