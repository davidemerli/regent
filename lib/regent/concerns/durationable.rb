# frozen_string_literal: true
module Regent
  module Concerns
    module Durationable
      def duration
        return 0 unless @start_time
        @end_time = Time.now if @end_time.nil?
        @end_time - @start_time
      end
    end
  end
end
