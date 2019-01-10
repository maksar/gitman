# frozen_string_literal: true

require_relative "dialog"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"
require_relative "../services/active_directory"

class ModifyRules < Dialog
  def initialize(bitbucket_factory = BitbucketFactory.new(Bitbucket), active_directory = ActiveDirectory.new)
    @bitbucket_factory = bitbucket_factory
    @active_directory = active_directory
  end

  def call(project, repository)
    @project = project
    @repository = repository
    Fiber.new do
      pull_requests
      force_push
      branch_model
      branch_permissions
      large_files_support
      commit_hooks
      answer("All done!")
    end
  end

  private

  def pull_requests
    option("Do you want set up minimal approvals and builds?") do
      group = request("What is the name of the project development group:")
      reply("Group has following members: #{(members = @active_directory.group_members(group)).join('; ')}")

      members = members.select { |member| @active_directory.access?(member) }
      reply("Only following people have access to bitbucket: #{members.join('; ')}")

      members = members.reject { |member| @active_directory.manager?(member) }
      reply("Only following people are not managers: #{members.join('; ')}")

      count = (members.size / 2.0).ceil
      reply("Setting up minimal approvals to half of the developer's teem (#{count}) and minimal builds to 1?")
      bitbucket.pull_requests(count, 1)

      default_reviewers(members, count)
    end
  end

  def default_reviewers(members, count)
    option("Do you want set up default reviewers?") do
      reply("Adding default reviewers.")
      bitbucket.default_reviewers(members, count)
    end
  end

  def branch_model
    option("Do you want set up default branching model?") do
      reply("Setting up default branching model.")
      bitbucket.branch_model
    end
  end

  def branch_permissions
    option("Do you want set up branch permissions?") do
      reply("Setting branch permissions.")
      bitbucket.branch_permissions
    end
  end

  def large_files_support
    option("Do you want set up Large Files Support?") do
      reply("Enabling Large Files Support.")
      bitbucket.large_files_support
    end
  end

  def commit_hooks
    option("Do you want to set up commit hooks?") do
      jira_key = request("What is JIRA project key?")
      reply("Enabling commit hooks - jira task prefix, proper author name and email.")
      bitbucket.commit_hooks(jira_key)
    end
  end

  def force_push
    option("Do you want to disable force push into repository?") do
      bitbucket.enable_force_push
    end
  end

  def bitbucket
    @bitbucket_factory.repository(@project, @repository)
  end
end
