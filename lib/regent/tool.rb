module Regent
  class Tool
    def initialize(name, description)
      @name = name
      @description = description
    end

    attr_reader :name, :description

    def call(argument)
      raise NotImplementedError, "Tool #{name} has not implemented the execute method"
    end
  end
end
