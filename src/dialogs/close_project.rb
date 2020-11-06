# frozen_string_literal: true

require_relative "base"
require_relative "close_repository"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class CloseProject < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), close_repository = CloseRepository.new(bitbucket_factory))
      @bitbucket_factory = bitbucket_factory
      @close_repository = close_repository
    end

    def call
      Fiber.new { project }
    end

    private

    def project
      @project = request("What is Bitbucket PROJECT key?")
      return answer("There is no such project.") unless (info = bitbucket.project_info)
      return answer("Project #{@project} is already closed.") if info["name"].start_with?(Services::Bitbucket::CLOSED_PROJECT_PREFIX)

      reply("Ok, #{@project} project exist.")
      ask("Do you want to close whole project?", proc { @close_repository.call(@project) }) { close }
    end

    def close
      bitbucket.close_project
      answer("Project closed!", link: bitbucket.project_link(Services::Bitbucket::BROWSER_PREFIX))
    end

    def bitbucket
      @bitbucket_factory.project(@project)
    end
  end
end
