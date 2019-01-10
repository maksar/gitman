# frozen_string_literal: true

require "json"
require "rest-client"
require "base64"
require "cgi"
require "active_support/core_ext/object/try"

class Bitbucket
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

  def projects_link
    "#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/api/1.0/projects"
  end

  def project_link
    projects_link + "/#{@project}"
  end

  def repository_link
    project_link + "/repos/#{@repository}"
  end

  def pull_requests(approvals_count, builds_count)
    post(
      "#{repository_link}/settings/pull-requests",
      mergeConfig: { defaultStrategy: { id: "no-ff" }, strategies: [{ id: "no-ff" }] },
      requiredAllApprovers: false,
      requiredApprovers: approvals_count,
      requiredAllTasksComplete: true,
      requiredSuccessfulBuilds: builds_count
    )
  end

  def enable_force_push
    switch("#{repository_link}/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook/enabled")
  end

  def branch_model
    put(
      "#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/branch-utils/1.0/projects/#{@project}/repos/#{@repository}/branchmodel/configuration",
      development: { useDefault: true },
      types: [
        { id: "BUGFIX", displayName: "Bugfix", enabled: true, prefix: "bugfix/" },
        { id: "FEATURE", displayName: "Feature", enabled: true, prefix: "feature/" },
        { id: "HOTFIX", displayName: "Hotfix", enabled: true, prefix: "hotfixme/" },
        { id: "RELEASE", displayName: "Release", enabled: true, prefix: "release/" }
      ]
    )
  end

  def large_files_support
    switch("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/git-lfs/admin/projects/#{@project}/repos/#{@repository}/enabled")
  end

  def commit_hooks(jira_key)
    put("#{repository_link}/settings/hooks/com.isroot.stash.plugin.yacc:yaccHook/settings",
        requireMatchingAuthorName: true, "errorMessage.COMMITTER_NAME": "author name is wrong",
        requireMatchingAuthorEmail: true, committerEmailRegex: "", "errorMessage.COMMITTER_EMAIL": "email is wrong", "errorMessage.COMMITTER_EMAIL_REGEX": "",
        commitMessageRegex: "", excludeMergeCommits: true, "errorMessage.COMMIT_REGEX": "",
        requireJiraIssue: true, ignoreUnknownIssueProjectKeys: true, issueJqlMatcher: "project = #{jira_key}", "errorMessage.ISSUE_JQL": "",
        branchNameRegex: "", "errorMessage.BRANCH_NAME": "", excludeBranchRegex: "",
        errorMessageHeader: "", errorMessageFooter: "",
        excludeByRegex: "", excludeUsers: "")
    switch("#{repository_link}/settings/hooks/com.isroot.stash.plugin.yacc:yaccHook/enabled")
  end

  def branch_permissions
    post(
      "#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/branch-permissions/2.0/projects/#{@project}/repos/#{@repository}/restrictions",
      type: "pull-request-only",
      matcher: {
        id: "master, dev, develop, development, prod, production, stage, staging",
        displayId: "master, dev, develop, development, prod, production, stage, staging",
        type: { id: "PATTERN", name: "Pattern" },
        active: true
      },
      users: [], groups: [], accessKeys: []
    )
  end

  def default_reviewers(members, count)
    post(
      "#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/default-reviewers/1.0/projects/#{@project}/repos/#{@repository}/condition",
      sourceMatcher: {
        active: true,
        id: "ANY_REF_MATCHER_ID",
        displayId: "ANY_REF_MATCHER_ID",
        type: { id: "ANY_REF", name: "Any branch" }
      },
      targetMatcher: {
        active: true,
        id: "ANY_REF_MATCHER_ID",
        displayId: "ANY_REF_MATCHER_ID",
        type: { id: "ANY_REF", name: "Any branch" }
      },
      reviewers: members.map(&method(:user)).compact, requiredApprovals: count
    )
  end

  private

  def user(full_name)
    (get("#{ENV.fetch('GITMAN_BITBUCKET_URL')}/rest/api/1.0/admin/users?filter=#{CGI.escape(full_name)}").try { |result| result["values"] } || []).first.try { |user_info| { id: user_info["id"] } }
  end

  def headers
    { Authorization: "Basic #{auth}", content_type: :json }
  end

  def auth
    Base64.encode64([ENV.fetch("GITMAN_BITBUCKET_USERNAME"), ENV.fetch("GITMAN_BITBUCKET_PASSWORD")].join(":")).strip
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
