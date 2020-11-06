# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

class ProjectInfo < ActiveSupport::HashWithIndifferentAccess
  def initialize(key, hash = {})
    super(hash)
    @key = key
  end

  attr_reader :key

  def name
    fetch(:name)
  end

  def description
    fetch(:description)
  end

  def type
    fetch(:type)
  end
end
