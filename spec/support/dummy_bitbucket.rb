# frozen_string_literal: true

require_relative "../../services/bitbucket"
require_relative "project_info"
require_relative "repository_info"

class DummyBitbucket < Bitbucket
  def initialize(conversation, project_info, repository_info)
    super(project_info&.key, repository_info&.slug)
    @conversation = conversation
    @project_info = project_info
    @repository_info = repository_info
  end

  attr_reader :project_info
  attr_reader :repository_info

  def assign(project, repository)
    @project = project
    @repository = repository
  end

  def create_project(name, description)
    @conversation.service("create_project(#{name}, #{description})")
    @project_info = ProjectInfo.new(@project, key: @project, name: name, description: description, type: "normal")
  end

  def create_repository(name)
    @conversation.service("create_repository(#{name})")
    @repository_info = RepositoryInfo.new(@repository, slug: @repository, name: name, type: "normal")
  end

  def pull_requests(approvals_count, builds_count)
    @conversation.service("pull_requests(#{approvals_count}, #{builds_count})")
  end

  def enable_force_push
    @conversation.service("enable_force_push()")
  end

  def branch_model
    @conversation.service("branch_model()")
  end

  def large_files_support
    @conversation.service("large_files_support()")
  end

  def commit_hooks(jira_key)
    @conversation.service("commit_hooks(#{jira_key})")
  end

  def branch_permissions
    @conversation.service("branch_permissions()")
  end

  def default_reviewers(members, count)
    @conversation.service("default_reviewers([#{members.join(', ')}], #{count})")
  end

  def group_write_access(group)
    @conversation.service("group_write_access(#{group})")
  end

  def personal_admin_access(administrators)
    @conversation.service("personal_admin_access([#{administrators.join(', ')}])")
  end
end
