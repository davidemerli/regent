module Regent
  class Logger
    def initialize
      @pastel = Pastel.new
      @spinner = TTY::Spinner.new("#{@pastel.cyan("[:spinner] :title")}", format: :dots)
    end

    attr_reader :spinner

    def start
      spinner.auto_spin
    end

    def stop
      spinner.stop
    end

    def log(message)
      if $stdout.isatty
        spinner.update(title: message)
        start unless spinner.spinning?
      else
        puts message
      end
    end

    def success(message)
      spinner.success(@pastel.cyan(message))
    end

    def error(message)
      spinner.error(@pastel.red(message))
    end
  end
end
