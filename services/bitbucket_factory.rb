# frozen_string_literal: true

require_relative "bitbucket"

class BitbucketFactory
  def initialize(bitbucket_class = Bitbucket)
    @bitbucket_class = bitbucket_class
  end

  def project(project)
    repository(project, nil)
  end

  def repository(project, repository)
    @bitbucket_class.new(project, repository)
  end
end
