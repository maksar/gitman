# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

class RepositoryInfo < ActiveSupport::HashWithIndifferentAccess
  def initialize(slug, hash = {})
    super(hash.merge(slug: slug))
    @slug = slug
  end

  attr_reader :slug

  def name
    fetch(:name)
  end

  def description
    fetch(:description)
  end
end
