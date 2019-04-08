# frozen_string_literal: true

require_relative "base"
require_relative "../services/bitbucket_factory"
require_relative "../services/bitbucket"
require_relative "../services/active_directory"

module Dialogs
  class ModifyRules < Base
    def initialize(bitbucket_factory = Services::BitbucketFactory.new(Services::Bitbucket), active_directory = Services::ActiveDirectory.new)
      @bitbucket_factory = bitbucket_factory
      @active_directory = active_directory
    end

    def call(project, repository)
      @project = project
      @repository = repository
      Fiber.new do
        permissions
        pull_requests
        branches
        features
        hooks
        answer("All done!")
      end
    end

    private

    def permissions
      option("Do you want to set up permissions for the project?") do
        group_access
        admin_access
      end
    end

    def branches
      branch_model
      branch_permissions
    end

    def features
      force_push
      large_files_support
    end

    def admin_access
      administrators = @active_directory.group_members(@group) & @active_directory.group_members("Tech Coordinators", Services::ActiveDirectory::GROUPS_DN)

      if administrators.empty?
        reply("There is no technical coordinators in the #{@group} group.")
        administrators = [request("Username of the technical coordinator:")]
      end

      bitbucket.personal_admin_access(administrators)
      reply("Granted admin access for the people #{administrators.join(', ')}.")
    end

    def group_access
      reply("Cannot find any members in group #{@group}.") while @active_directory.group_members(@group = request("What is the name of the project development group:")).empty?

      bitbucket.group_write_access(@group)
      reply("Granted write access for the group #{@group}.")
    end

    def pull_requests
      option("Do you want to set up minimal approvals and builds?") do
        @group ||= request("What is the name of the project development group:")

        reply("Group #{@group} has following members: #{join(members = @active_directory.group_members(@group))}")
        reply("Only following people have access to bitbucket: #{join(members = members.select { |member| @active_directory.access?(member) })}")
        reply("Only following people are not managers: #{join(members = members.reject { |member| @active_directory.manager?(member) })}")

        count = (members.size / 2.0).ceil
        reply("Setting up minimal approvals to half of the developer's team (#{count}) and minimal builds to 1?")
        bitbucket.pull_requests(count, 1)

        default_reviewers(members, count)
      end
    end

    def join(members)
      members.join("; ")
    end

    def default_reviewers(members, count)
      option("Do you want to set up default reviewers?") do
        reply("Adding default reviewers.")
        bitbucket.default_reviewers(members, count)
      end
    end

    def branch_model
      option("Do you want to set up default branching model?") do
        reply("Setting up default branching model.")
        bitbucket.branch_model
      end
    end

    def branch_permissions
      option("Do you want to set up branch permissions?") do
        reply("Setting branch permissions.")
        bitbucket.branch_permissions
      end
    end

    def large_files_support
      option("Do you want to set up Large Files Support?") do
        reply("Enabling Large Files Support.")
        bitbucket.large_files_support
      end
    end

    def hooks
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
end
