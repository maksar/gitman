# frozen_string_literal: true

require_relative "base"
require_relative "reopen_repository"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class ReopenProject < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), reopen_repository = ReopenRepository.new(bitbucket_factory))
      @bitbucket_factory = bitbucket_factory
      @reopen_repository = reopen_repository
    end

    def call
      Fiber.new { project }
    end

    private

    def project
      @project = request("What is Bitbucket PROJECT key?")
      return answer("There is no such project.") unless (info = bitbucket.project_info)

      reply("Ok, #{@project} project exist.")

      unless info["name"].start_with?(Services::Bitbucket::CLOSED_PROJECT_PREFIX)
        return ask("Project #{@project} is not closed. Do you want to reopen a particalar repository?") { @reopen_repository.call(@project) }
      end

      ask("Do you want to reopen whole project?", proc { @reopen_repository.call(@project) }) { reopen }
    end

    def reopen
      bitbucket.reopen_project
      answer("Project reopened!", link: bitbucket.project_link(Services::Bitbucket::BROWSER_PREFIX))
    end

    def bitbucket
      @bitbucket_factory.project(@project)
    end
  end
end
