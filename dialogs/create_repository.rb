# frozen_string_literal: true

require_relative "base"
require_relative "modify_rules"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"

module Dialogs
  class CreateRepository < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), modify_rules = ModifyRules.new(bitbucket_factory))
      @bitbucket_factory = bitbucket_factory
      @modify_rules = modify_rules
    end

    def call(project)
      @project = project
      Fiber.new do
        repository
      end
    end

    private

    def repository
      @repository = request("What is Bitbucket repository key?")
      if (info = bitbucket.repository_info)
        reply("Ok, #{@repository} repository already exist in #{@project} project.")
        print_info(info)
        @modify_rules.call(@project, @repository)
      else
        reply("There is no such repository in #{@project} project.")
        ask("Do you want to create it?", &method(:create_repository))
      end
    end

    def create_repository
      name = request("Specify human readable repository name:")
      description = request("Specify repository description:")
      ask("We are about to create repository with name '#{name}', description '#{description}'") do
        info = bitbucket.create_repository(name, description)
        @repository = info.fetch("slug")
        print_info(info)
        reply("Repository created!", link: bitbucket.repository_link(Services::Bitbucket::BROWSER_PREFIX))
        @modify_rules.call(@project, @repository)
      end
    end

    def print_info(info)
      reply("Name: #{info.fetch('name')}")
      info["description"].try { |description| reply("Description: #{description}") }
    end

    def bitbucket
      @bitbucket_factory.repository(@project, @repository)
    end
  end
end
