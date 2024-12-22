# frozen_string_literal: true

require 'securerandom'
require 'pastel'
require 'tty-spinner'
require 'zeitwerk'

module Regent
  class Error < StandardError; end
  # Your code goes here...

  loader = Zeitwerk::Loader.for_gem
  loader.setup
end
