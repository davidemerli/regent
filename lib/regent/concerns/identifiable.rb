require 'securerandom'

module Regent
  module Concerns
    module Identifiable
      def self.included(base)
        base.class_eval do
          attr_reader :id
        end
      end

      private

      def generate_id
        @id = SecureRandom.uuid
      end

      def initialize(*)
        generate_id
        super
      end
    end
  end
end
