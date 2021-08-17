# frozen_string_literal: true

require "json"
require "rest-client"
require "cgi"
require "active_support/core_ext/object/try"
require "active_support/core_ext/object/blank"

module Services
  class Bitbucket
    API_PREFIX = "/rest/api/1.0"
    BROWSER_PREFIX = ""

    BRANCHES = %w[master dev develop development prod production stage staging].freeze
    MERGE_RESTRICTINOS = %w[fast-forward-only pull-request-only no-deletes].freeze

    CLOSED_REPOSITORY_PREFIX = "CLOSED_"
    CLOSED_PROJECT_PREFIX = "[Closed]"

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
      put(projects_link, key: @project, name: name, description: description, public: false)
    end

    def create_repository(name, description)
      post("#{project_link}/repos", name: name, description: description, public: false, forkable: false)
    end

    def projects_link(prefix = API_PREFIX)
      "#{ENV.fetch('GITMAN_BITBUCKET_URL')}#{prefix}/projects"
    end

    def project_link(prefix = API_PREFIX)
      projects_link(prefix) + "/#{@project}"
    end

    def repository_link(prefix = API_PREFIX)
      project_link(prefix) + "/repos/#{@repository}"
    end

    def pull_requests(approvals_count, builds_count)
      post("#{repository_link}/settings/pull-requests",
           mergeConfig: { defaultStrategy: { id: "no-ff" }, strategies: [{ id: "no-ff" }] },
           requiredAllApprovers: false, requiredApprovers: approvals_count, requiredAllTasksComplete: true, requiredSuccessfulBuilds: builds_count)
      switch("#{repository_link}/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:needs-work-merge-check/enabled")
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
          commitMessageRegex: "((?s).*\\b#{jira_key}-(\\d+|X)\\b.*)|((?s)^TeamCity change in.*)", requireMatchingAuthorEmail: true, excludeMergeCommits: true)
      switch("#{repository_link}/settings/hooks/com.isroot.stash.plugin.yacc:yaccHook/enabled")
    end

    def branch_permissions
      BRANCHES.product(MERGE_RESTRICTINOS).each do |branch, restriction|
        post("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/branch-permissions/2.0/projects/#{@project}/repos/#{@repository}/restrictions",
             type: restriction, users: [], groups: [], accessKeys: [],
             matcher: { id: branch, displayId: branch, type: { id: "PATTERN", name: "Pattern" }, active: true })
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
      administrators.map { |administrator| switch("#{repository_link}/permissions/users?permission=REPO_ADMIN&name=#{CGI.escape(user(administrator)['name'])}") }
    end

    def close_repository
      close(CLOSED_REPOSITORY_PREFIX, &method(:repository_link))
    end

    def reopen_repository
      reopen(CLOSED_REPOSITORY_PREFIX, &method(:repository_link))
      reopen(CLOSED_PROJECT_PREFIX, &method(:project_link))
    end

    def close_project
      close("#{CLOSED_PROJECT_PREFIX} ", &method(:project_link))
      open_repositories.each do |repo|
        @repository = repo["slug"]
        close(CLOSED_REPOSITORY_PREFIX, &method(:repository_link))
      end
    end

    def reopen_project
      reopen(CLOSED_PROJECT_PREFIX, &method(:project_link))
      closed_repositories.each do |repo|
        @repository = repo["slug"]
        reopen(CLOSED_REPOSITORY_PREFIX, &method(:repository_link))
      end
    end

    def open_repositories
      repositories.reject { |repo| repo["name"].start_with?(CLOSED_REPOSITORY_PREFIX) }
    end

    def closed_repositories
      repositories.select { |repo| repo["name"].start_with?(CLOSED_REPOSITORY_PREFIX) }
    end

    private

    def repositories
      get("#{project_link}/repos?limit=100").fetch("values", [])
    end

    def reopen(closed_name_prefix)
      get(yield).tap do |info|
        description = info["description"].to_s.delete_prefix(CLOSED_PROJECT_PREFIX).presence || "empty description"
        put(yield, name: info["name"].to_s.delete_prefix(closed_name_prefix).strip, description: description)
      end
    end

    def close(closed_name_prefix)
      [["#{yield}/permissions/groups", proc { |info| "#{yield}/permissions/groups?name=#{CGI.escape(info['group']['name'])}" }],
       ["#{yield}/permissions/users", proc { |info| "#{yield}/permissions/users?name=#{CGI.escape(info['user']['name'])}" }],
       ["#{yield('/rest/keys/1.0')}/ssh", proc { |info| "#{yield('/rest/keys/1.0')}/ssh/#{info['key']['id']}" }]].each do |get_url, delete_url|
        get("#{get_url}?limit=100").fetch("values", []).each { |info| delete(delete_url.call(info)) }
      end
      get(yield).tap { |info| put(yield, name: closed_name_prefix + info["name"].to_s, description: "#{CLOSED_PROJECT_PREFIX} #{info['description']}") }
    end

    def user(full_name)
      get("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/api/1.0/admin/users?filter=#{CGI.escape(full_name)}").try { |result| result["values"] }.try(&:first)
    end

    def headers
      { Authorization: "Bearer #{ENV.fetch('GITMAN_BITBUCKET_TOKEN')}", content_type: :json }
    end

    def post(url, data)
      JSON.parse(request(url, :post, payload: data.to_json).body)
    end

    def put(url, data)
      JSON.parse(request(url, :put, payload: data.to_json).body)
    end

    def delete(url)
      request(url, :delete)
    end

    def switch(url)
      request(url, :put, payload: "")
    end

    def get(url)
      JSON.parse(request(url, :get).body)
    rescue RestClient::NotFound
      nil
    end

    def request(url, method, params = {})
      RestClient::Request.execute(params.merge(url: url, method: method, headers: headers, ssl_ca_file: ENV.fetch("GITMAN_BITBUCKET_CERTIFICATE"), verify_ssl: OpenSSL::SSL::VERIFY_PEER))
    rescue RestClient::TemporaryRedirect => e
      e.response.follow_redirection
    end
  end
end
