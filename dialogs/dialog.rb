# frozen_string_literal: true

require "facets/class/cattr"

class Dialog
  POSITIVE = "Yes"
  NEGATIVE = "No"

  cattr_accessor :default

  private

  def ask(question)
    if request(question, answers: [[POSITIVE, NEGATIVE]]) == POSITIVE
      yield
    else
      answer("Ok then.")
    end
  end

  def request(question, answers: nil, link: nil)
    Fiber.yield(:question, text: question, answers: answers, link: link)
  end

  def reply(statement)
    Fiber.yield(:statement, text: statement)
  end

  def answer(answer, link: nil)
    request(answer, link: link)
    self.class.default.call
  end
end
