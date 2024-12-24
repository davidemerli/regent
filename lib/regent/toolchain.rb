# frozen_string_literal: true

module Regent
  class Toolchain
    def initialize(tools)
      @tools = tools
    end

    attr_reader :tools

    def find(name)
      tools.find { |tool| tool.name.downcase == name.downcase }
    end

    def to_s
      tools.map(&:to_s).join("\n")
    end
  end
end
