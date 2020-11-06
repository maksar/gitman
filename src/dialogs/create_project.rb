# frozen_string_literal: true

require_relative "base"
require_relative "create_repository"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class CreateProject < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), create_repository = CreateRepository.new(bitbucket_factory))
      @bitbucket_factory = bitbucket_factory
      @create_repository = create_repository
    end

    def call
      Fiber.new { project }
    end

    private

    def project
      @project = request("What is Bitbucket PROJECT key?")
      if (info = bitbucket.project_info)
        reply("Ok, #{@project} project already exist.")
        print_info(info)
        @create_repository.call(@project)
      else
        reply("There is no such project.")
        ask("Do you want to create it?", &method(:create))
      end
    end

    def create
      name = request("Specify project name (human readable):")
      description = request("Specify project description:")
      ask("We are about to create project with name '#{name}', key '#{@project}', description '#{description}'") do
        print_info(bitbucket.create_project(name, description))
        answer("Project created!", link: bitbucket.project_link(Services::Bitbucket::BROWSER_PREFIX))
      end
    end

    def print_info(info)
      reply("Name: #{info.fetch('name')}")
      reply("Type: #{info.fetch('type')}")
      info["description"].try { |description| reply("Description: #{description}") }
    end

    def bitbucket
      @bitbucket_factory.project(@project)
    end
  end
end
