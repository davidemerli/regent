# frozen_string_literal: true

module Regent
  module Concerns
    module Toolable
      def self.included(base)
        base.class_eval do
          class << self
            def tool(name, description)
              @function_tools ||= []
              @function_tools << { name: name, description: description }
            end

            def function_tools
              @function_tools || []
            end
          end
        end
      end
    end
  end
end
