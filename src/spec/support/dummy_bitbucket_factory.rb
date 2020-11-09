# frozen_string_literal: true

require_relative "../../services/bitbucket_factory"

class DummyBitbucketFactory < Services::BitbucketFactory
  def initialize(bitbucket)
    @bitbucket = bitbucket
  end

  def repository(project, repository)
    @bitbucket.tap do |bitbucket|
      bitbucket.assign(project, repository)
    end
  end
end
