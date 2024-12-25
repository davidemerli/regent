# frozen_string_literal: true

module Regent
  class Session
    include Concerns::Identifiable
    include Concerns::Durationable

    class SessionError < StandardError; end
    class InactiveSessionError < SessionError; end
    class AlreadyStartedError < SessionError; end

    def initialize
      super()

      @spans = []
      @messages = []
      @start_time = nil
      @end_time = nil
    end

    attr_reader :id, :spans, :messages, :start_time, :end_time

    # Starts the session
    # @raise [AlreadyStartedError] if session is already started
    # @return [void]
    def start
      raise AlreadyStartedError, "Session already started" if @start_time

      @start_time = Time.now.freeze
    end

    # Executes a new span in the session
    # @param type [Symbol, String] The type of span
    # @param options [Hash] Options for the span
    # @raise [InactiveSessionError] if session is not active
    # @return [String] The output of the span
    def exec(type, options = {}, &block)
      @spans << Span.new(type: type, arguments: options)
      current_span.run(&block)
    end

    # Completes the session and returns the result
    # @return [Object] The result of the last span
    # @raise [InactiveSessionError] if session is not active
    # @return [String] The result of the last span
    def complete
      raise InactiveSessionError, "Cannot complete inactive session" unless active?

      @end_time = Time.now.freeze
      result
    end

    # @return [Span, nil] The current span or nil if no spans exist
    def current_span
      @spans.last
    end

    # @return [String, nil] The output of the current span or nil if no spans exist
    def result
      current_span&.output
    end

    # @return [Boolean] Whether the session is currently active
    def active?
      start_time && end_time.nil?
    end

    # Adds a message to the session
    # @param message [String] The message to add
    # @raise [ArgumentError] if message is nil or empty
    def add_message(message)
      raise ArgumentError, "Message cannot be nil or empty" if message.nil? || message.empty?

      @messages << message
    end
  end
end
