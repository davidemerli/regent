module Regent
  class Session
    def initialize(agent)
      @id = SecureRandom.uuid
      @agent = agent
      @spans = []
      @start_time = nil
      @end_time = nil
    end

    attr_reader :id, :spans, :start_time, :end_time

    def start
      @start_time = Time.now
    end

    def continue(type, options = {})
      @spans << Span.new(self, type, options)
      result = spans.last.execute
      result
    end

    def complete(type, options = {})
      continue(type, options) if type

      @end_time = Time.now
      spans.last.output
    end

    def running?
      start_time && end_time.nil?
    end

    def duration
      end_time - start_time
    end

    def llm
      @agent.llm
    end
  end
end
