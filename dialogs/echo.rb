# frozen_string_literal: true

require_relative "dialog"

class Echo < Dialog
  def call(text)
    answer("Echo: #{text}")
  end
end
