# frozen_string_literal: true

require_relative "../../services/auth"

class DummyAuth < Services::Auth
  def initialize
    super(nil)
  end

  def allowed?(_uid)
    true
  end
end
