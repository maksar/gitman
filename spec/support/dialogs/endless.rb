# frozen_string_literal: true

require_relative "../../../dialogs/default"

module Dialogs
  class Endless < Default
    def initialize(repeats, mapping)
      @repeats = repeats
      super(mapping)
    end

    def call
      @repeats -= 1
      @mapping = {} if @repeats.zero?
      super
    end

    private

    def answer(answer, params = {})
      request(answer, params)
      Fiber.new { call }
    end
  end
end
