# frozen_string_literal: true

class DummyContinuation
  def call(*_)
    [:end, text: nil]
  end
end
