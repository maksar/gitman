# frozen_string_literal: true

require_relative "dialog"

class Greeter < Dialog
  def call(name = nil)
    answer("Hello #{name || request('What is your name?')}")
  end
end
