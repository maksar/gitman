# frozen_string_literal: true

require_relative "dialog"
require_relative "../services/bitbucket"

class CreateRepository < Dialog
  def initialize(bitbucket = Bitbucket.new)
    @bitbucket = bitbucket
  end

  def repository(project)
    repository = request("What is Bitbucket repository name?")
    if repository_info(project, repository)
      reply("Ok, #{repository} repository already exist in #{project} project.")
      ask("Do you want to modify the rules?") { modify_rules(project, repository) }
    else
      reply("There is no such repository in #{project} project.")
      ask("Do you want to create it?") { create_repository(project, repository) }
    end
  end

  private

  def repository_info(project, repository)
    @bitbucket.repository_info(project, repository)
  end

  def create_repository(project, repository)
    name = request("Specify repository name (human readable):")
    description = request("Specify repository description:")
    ask("We are about to create repository with name '#{name}', key '#{repository}', description '#{description}'") do
      print_info(@bitbucket.create_repository(project, repository, name, description))
      answer("Repository created!", link: @bitbucket.repository_link(project, repository))
    end
  end

  def modify_rules(_project, _repository)
    answer("Modifying rules...")
  end

  def print_info(info)
    reply("Name: #{info.fetch('name')}")
    reply("Description: #{info.fetch('description')}")
    reply("Type: #{info.fetch('type')}")
  end
end
