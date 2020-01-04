# frozen_string_literal: true

require "fiber"

module Dialogs
  class Base
    POSITIVE = "Yes"
    NEGATIVE = "No"

    private

    def ask(question, negative = -> { answer("Ok then.") })
      case request(question, answers: [[POSITIVE, NEGATIVE]])
      in POSITIVE then yield
      else negative.call
      end
    end

    def option(question, &block)
      ask(question, -> {}, &block)
    end

    def request(question, params = {})
      Fiber.yield(:question, params.merge(text: question))
    end

    def reply(statement, params = {})
      Fiber.yield(:statement, params.merge(text: statement))
    end

    def answer(answer, params = {})
      request(answer, params)
      Fiber.yield(:end)
    end
  end
end
