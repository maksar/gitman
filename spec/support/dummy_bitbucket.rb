# frozen_string_literal: true

require "facets/hash/symbolize_keys"

require_relative "../../services/bitbucket"

class DummyBitbucket < Bitbucket
  def initialize(conversation, project_info, repository_info)
    @conversation = conversation
    @project_info = project_info
    @repository_info = repository_info
  end

  def project_info(_project)
    @project_info
  end

  def repository_info(_project, _repository)
    @repository_info
  end

  def create_project(project, name, description)
    @conversation.service("create_project(#{project}, #{name}, #{description})")
    { key: project, name: name, description: description, type: "normal" }.stringify_keys
  end

  def create_repository(project, repository, name, description)
    @conversation.service("create_repository(#{project}, #{repository}, #{name}, #{description})")
    { key: repository, name: name, description: description, type: "normal" }.stringify_keys
  end
end
