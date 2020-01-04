# frozen_string_literal: true

require_relative "../../../dialogs/default"

module Dialogs
  class UnknownCommand < Default
    private

    def answer(answer, params = {})
      request(answer, params)
      Fiber.yield(:unknown)
    end
  end
end
