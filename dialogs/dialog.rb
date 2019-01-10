# frozen_string_literal: true

require "fiber"
require "active_support/core_ext/class/attribute_accessors"

class Dialog
  POSITIVE = "Yes"
  NEGATIVE = "No"

  cattr_accessor :default

  private

  def ask(question, negative = -> { answer("Ok then.") })
    if request(question, answers: [[POSITIVE, NEGATIVE]]) == POSITIVE
      yield
    else
      negative.call
    end
  end

  def option(question, &block)
    ask(question, -> {}, &block)
  end

  def request(question, answers: nil, link: nil)
    Fiber.yield(:question, text: question, answers: answers, link: link)
  end

  def reply(statement, link: nil)
    Fiber.yield(:statement, text: statement, link: link)
  end

  def answer(answer, link: nil)
    request(answer, link: link)
    self.class.default.call
  end
end
