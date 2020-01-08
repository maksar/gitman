# frozen_string_literal: true

class DummyStore < Hash
  def initialize(hash)
    super().merge!(**hash)
  end

  def transaction
    yield
  end
end
