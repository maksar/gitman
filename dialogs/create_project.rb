# frozen_string_literal: true

require_relative "dialog"
require_relative "create_repository"
require_relative "../services/bitbucket"

class CreateProject < Dialog
  def initialize(bitbucket = Bitbucket.new)
    @bitbucket = bitbucket
  end

  def call
    Fiber.new { project }
  end

  private

  def project
    project = request("What is Bitbucket PROJECT name?")
    if (info = project_info(project))
      reply("Ok, #{project} project already exist.")
      print_info(info)
      CreateRepository.new(@bitbucket).repository(project)
    else
      reply("There is no such project.")
      ask("Do you want to create it?") { create_project(project) }
    end
  end

  def project_info(project)
    @bitbucket.project_info(project)
  end

  def create_project(project)
    name = request("Specify project name (human readable):")
    description = request("Specify project description:")
    ask("We are about to create project with name '#{name}', key '#{project}', description '#{description}'") do
      print_info(@bitbucket.create_project(project, name, description))
      answer("Project created!", link: @bitbucket.project_link(project))
    end
  end

  def print_info(info)
    reply("Name: #{info.fetch('name')}")
    reply("Description: #{info.fetch('description')}")
    reply("Type: #{info.fetch('type')}")
  end
end
