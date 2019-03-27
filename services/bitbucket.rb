# frozen_string_literal: true

require "json"
require "rest-client"
require "base64"
require "cgi"
require "active_support/core_ext/object/try"

module Services
  class Bitbucket
    API_PREFIX = "/rest/api/1.0/projects"
    BROWSER_PREFIX = "/projects"

    def initialize(project, repository)
      @project = project
      @repository = repository
    end

    def project_info
      get(project_link)
    end

    def repository_info
      get(repository_link)
    end

    def create_project(name, description)
      post(projects_link, key: @project, name: name, description: description, public: false)
    end

    def create_repository(name)
      post("#{project_link}/repos", slug: @repository, name: name, public: false, forkable: false)
    end

    def projects_link(prefix = API_PREFIX)
      ENV.fetch("GITMAN_BITBUCKET_URL") + prefix
    end

    def project_link(prefix = API_PREFIX)
      projects_link(prefix) + "/#{@project}"
    end

    def repository_link(prefix = API_PREFIX)
      project_link(prefix) + "/repos/#{@repository}"
    end

    def pull_requests(approvals_count, builds_count)
      post(
        "#{repository_link}/settings/pull-requests",
        mergeConfig: { defaultStrategy: { id: "no-ff" }, strategies: [{ id: "no-ff" }] },
        requiredAllApprovers: false, requiredApprovers: approvals_count, requiredAllTasksComplete: true, requiredSuccessfulBuilds: builds_count
      )
    end

    def enable_force_push
      switch("#{repository_link}/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook/enabled")
    end

    def branch_model
      put("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/branch-utils/1.0/projects/#{@project}/repos/#{@repository}/branchmodel/configuration",
          development: { useDefault: true },
          types: [{ id: "BUGFIX", displayName: "Bugfix", enabled: true, prefix: "bugfix/" },
                  { id: "FEATURE", displayName: "Feature", enabled: true, prefix: "feature/" },
                  { id: "HOTFIX", displayName: "Hotfix", enabled: true, prefix: "hotfixme/" },
                  { id: "RELEASE", displayName: "Release", enabled: true, prefix: "release/" }])
    end

    def large_files_support
      switch("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/git-lfs/admin/projects/#{@project}/repos/#{@repository}/enabled")
    end

    def commit_hooks(jira_key)
      put("#{repository_link}/settings/hooks/com.isroot.stash.plugin.yacc:yaccHook/settings",
          commitMessageRegex: "#{jira_key}-\\d+.*", requireJiraIssue: true, ignoreUnknownIssueProjectKeys: true,
          requireMatchingAuthorName: true, requireMatchingAuthorEmail: true, excludeMergeCommits: true)
      switch("#{repository_link}/settings/hooks/com.isroot.stash.plugin.yacc:yaccHook/enabled")
    end

    def branch_permissions
      %w[master dev develop development prod production stage staging].each do |branch|
        %w[fast-forward-only pull-request-only no-deletes].each do |restriction|
          post("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/branch-permissions/2.0/projects/#{@project}/repos/#{@repository}/restrictions",
               type: restriction, users: [], groups: [], accessKeys: [],
               matcher: { id: branch, displayId: branch, type: { id: "PATTERN", name: "Pattern" }, active: true })
        end
      end
    end

    def default_reviewers(members, count)
      post("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/default-reviewers/1.0/projects/#{@project}/repos/#{@repository}/condition",
           sourceMatcher: { active: true, id: "ANY_REF_MATCHER_ID", displayId: "ANY_REF_MATCHER_ID", type: { id: "ANY_REF", name: "Any branch" } },
           targetMatcher: { active: true, id: "ANY_REF_MATCHER_ID", displayId: "ANY_REF_MATCHER_ID", type: { id: "ANY_REF", name: "Any branch" } },
           reviewers: members.map(&method(:user)).compact.map { |user| { id: user["id"] } }, requiredApprovals: count)
    end

    def group_write_access(group)
      switch("#{repository_link}/permissions/groups?permission=REPO_WRITE&name=#{CGI.escape(group)}")
    end

    def personal_admin_access(administrators)
      administrators.map do |administrator|
        switch("#{repository_link}/permissions/users?permission=REPO_ADMIN&name=#{CGI.escape(user(administrator)['name'])}")
      end
    end

    private

    def user(full_name)
      get("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/api/1.0/admin/users?filter=#{CGI.escape(full_name)}").try { |result| result["values"] }.try(&:first)
    end

    def headers
      auth = Base64.encode64([ENV.fetch("GITMAN_BITBUCKET_USERNAME"), ENV.fetch("GITMAN_BITBUCKET_PASSWORD")].join(":")).strip
      { Authorization: "Basic #{auth}", content_type: :json }
    end

    def post(url, data)
      JSON.parse(RestClient.post(url, data.to_json, headers).body)
    end

    def put(url, data)
      JSON.parse(RestClient.put(url, data.to_json, headers).body)
    end

    def switch(url)
      RestClient.put(url, "", headers)
    end

    def get(url)
      JSON.parse(RestClient.get(url, headers).body)
    rescue RestClient::NotFound
      nil
    end
  end
end
