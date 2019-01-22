# frozen_string_literal: true

require_relative "../../auth"

class DummyAuth < Auth
  def allowed?(_uid)
    true
  end
end
