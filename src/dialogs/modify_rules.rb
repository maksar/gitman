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
      option("Do you want to set up permissions for the repository?") do
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
      if (administrators = @active_directory.project_group_members(development_group) & @active_directory.technical_coordinators).empty?
        reply("There are no technical coordinators in the #{development_group} group.")
        administrators = [request("Username of the technical coordinator:")]
      end

      bitbucket.personal_admin_access(administrators)
      reply("Granted admin access for the people #{administrators.join(', ')}.")
    end

    def group_access
      bitbucket.group_write_access(development_group)
      reply("Granted write access for the group #{development_group}.")
    end

    def pull_requests
      option("Do you want to set up minimal approvals?") do
        reply("Group #{development_group} has following members: #{join(members = @active_directory.project_group_members(development_group))}")
        reply("Only following people have access to bitbucket: #{join(members = members.select { |member| @active_directory.access?(member) })}")
        reply("Only following people are not managers: #{join(members = members.reject { |member| @active_directory.manager?(member) })}")
        count = (members.size / 2.0).ceil

        reply("Setting up minimal approvals to half of the developer's team (#{count}) and minimal builds to #{minimal_builds}.")

        bitbucket.pull_requests(count, minimal_builds)
        default_reviewers(members, count)
      end
    end

    def join(members)
      members.join("; ")
    end

    def development_group
      @development_group ||=
        begin
          group = request("What is the name of the project development group:")

          if @active_directory.project_group_members(group).empty?
            reply("Cannot find any members in group #{group}.")
            development_group
          else
            group
          end
        end
    end

    def minimal_builds
      @minimal_builds ||=
        begin
          builds_number = 0
          option("Do you want to set up minimal builds?") do
            builds_number = request("What is the number of builds you want to require:")
          end
          builds_number.to_i
        end
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
