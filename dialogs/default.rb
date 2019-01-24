# frozen_string_literal: true

require "fiber"

require_relative "base"

module Dialogs
  class Default < Base
    def initialize(mapping)
      @mapping = mapping
    end

    def call
      Fiber.new do |message|
        @mapping[message]&.call || answer("What can I do for you?")
      end
    end
  end
end
