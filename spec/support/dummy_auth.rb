# frozen_string_literal: true

require_relative "../../services/auth"

class DummyAuth < Services::Auth
  def allowed?(_uid)
    true
  end
end
