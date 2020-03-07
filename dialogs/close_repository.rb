# frozen_string_literal: true

require_relative "base"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class CloseRepository < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket))
      @bitbucket_factory = bitbucket_factory
    end

    def call(project)
      @project = project
      Fiber.new { repository }
    end

    private

    def repository
      @repository = request("What is Bitbucket repository key?")
      return answer("There is no such repository in #{@project} project.") unless (info = bitbucket.repository_info)
      return answer("Repository #{@repository} is already closed.") if info["name"].start_with?(Services::Bitbucket::CLOSED_REPOSITORY_PREFIX)

      reply("Ok, #{@repository} repository exist in #{@project} project.")
      close
    end

    def close
      bitbucket.close_repository

      if bitbucket.open_repositories.size.positive?
        answer("Repository closed!", link: bitbucket.repository_link(Services::Bitbucket::BROWSER_PREFIX))
      else
        reply("Repository closed!", link: bitbucket.repository_link(Services::Bitbucket::BROWSER_PREFIX))
        ask("All repositories in #{@project} project are closed. Do you alse want to close the project itself?") do
          bitbucket.close_project
          answer("Project closed!", link: bitbucket.project_link(Services::Bitbucket::BROWSER_PREFIX))
        end
      end
    end

    def bitbucket
      @bitbucket_factory.repository(@project, @repository)
    end
  end
end
