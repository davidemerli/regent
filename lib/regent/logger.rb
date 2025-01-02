# frozen_string_literal: true

module Regent
  class Logger
    COLORS = %i[dim green yellow red blue cyan clear].freeze

    class << self
      def warn_and_exit(message)
        warn message
        exit 1
      end
    end

    def initialize(output: $stdout)
      @pastel = Pastel.new
      @spinner = build_spinner(spinner_symbol, output)
      @nested_spinner = build_spinner("#{dim(" ├──")}#{spinner_symbol}", output)
    end

    attr_reader :spinner, :nested_spinner

    def info(label:, message:, duration: nil, type: nil, meta: nil, top_level: false)
      current_spinner = top_level ? spinner : nested_spinner
      current_spinner.update(title: format_message(label, message, duration, type, meta))
      current_spinner
    end

    def start(**args)
      info(**args).auto_spin
    end

    def success(**args)
      info(**args).success
    end

    def error(**args)
      info(**args).error
    end

    private

    def format_message(label, message, duration, type, meta)
      parts = []
      parts << "#{dim("[")}#{cyan(label)}"
      parts << "#{dim(" ❯")} #{yellow(type)}" if type
      parts << dim("]")
      parts << dim("[#{meta}]") if meta
      parts << dim("[#{duration.round(2)}s]") if duration
      parts << dim(":")
      parts << clear(" #{message}")

      parts.join
    end

    def spinner_symbol
      "#{dim("[")}#{green(":spinner")}#{dim("]")}"
    end

    def build_spinner(spinner_format, output)
      TTY::Spinner.new("#{spinner_format} :title", format: :dots, output: output)
    end

    COLORS.each do |color|
      define_method(color) do |message|
        @pastel.send(color, message)
      end
    end
  end
end
