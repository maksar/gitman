# frozen_string_literal: true

require_relative "../../../dialogs/default"

module Dialogs
  class Endless < Default
    private

    def answer(answer, params = {})
      request(answer, params)
      Fiber.new { call }
    end
  end
end
