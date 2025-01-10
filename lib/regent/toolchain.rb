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

    def add(tool, context)
      @tools << Regent::Tool.new(name: tool[:name].to_s, description: tool[:description]).instance_eval do
        raise "A tool method '#{tool[:name]}' is missing in the #{context.class.name}" unless context.respond_to?(tool[:name])

        define_singleton_method(:call){ |*args| context.send(tool[:name], *args) }
        self
      end
    end

    def to_s
      tools.map(&:to_s).join("\n")
    end

    private

    def tool_missing_error(tool_name, context_name)
      "A tool method '#{tool_name}' is missing in the #{context_name}"
    end
  end
end
