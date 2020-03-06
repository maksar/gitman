# frozen_string_literal: true

require_relative "base"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class ReopenRepository < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), modify_rules = ModifyRules.new(bitbucket_factory))
      @bitbucket_factory = bitbucket_factory
      @modify_rules = modify_rules
    end

    def call(project)
      @project = project
      Fiber.new { repository }
    end

    private

    def repository
      @repository = request("What is Bitbucket repository key?")
      return answer("There is no such repository in #{@project} project.") unless (info = bitbucket.repository_info)
      return answer("Repository #{@repository} is not closed.") unless info["name"].start_with?(Services::Bitbucket::CLOSED_REPOSITORY_PREFIX)

      reply("Ok, closed #{@repository} repository exist in #{@project} project.")
      reopen
    end

    def reopen
      bitbucket.reopen_repository
      reply("Repository and a project reopened!", link: bitbucket.repository_link(Services::Bitbucket::BROWSER_PREFIX))
      @modify_rules.call(@project, @repository)
    end

    def bitbucket
      @bitbucket_factory.repository(@project, @repository)
    end
  end
end
