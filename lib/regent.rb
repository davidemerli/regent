# frozen_string_literal: true

require 'securerandom'
require 'langchain'
require 'pastel'
require 'tty-spinner'
require 'zeitwerk'

module Regent
  class Error < StandardError; end
  # Your code goes here...

  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect("llm" => "LLM")
  loader.setup
end
