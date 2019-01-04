# frozen_string_literal: true

require "json"
require "rest-client"
require "base64"

class Bitbucket
  def project_info(project)
    get(project_link(project))
  end

  def repository_info(project, repository)
    get(repository_link(project, repository))
  end

  def create_project(project, name, description)
    post(projects_link, key: project, name: name, description: description)
  end

  def create_repository(project, repository, name, description)
    post(project_link(project), key: repository, name: name, description: description, forkable: false)
  end

  def projects_link
    "https://git.itransition.com/rest/api/1.0/projects"
  end

  def project_link(project)
    projects_link + "/#{project}"
  end

  def repository_link(project, repository)
    project_link(project) + "/repos/#{repository}"
  end

  private

  def headers
    { Authorization: "Basic #{auth}", content_type: :json }
  end

  def auth
    Base64.encode64([ENV.fetch("GITMAN_BITBUCKET_USERNAME"), ENV.fetch("GITMAN_BITBUCKET_PASSWORD")].join(":")).strip
  end

  def post(url, data)
    JSON.parse(RestClient.post(url, data.to_json, headers).body)
  end

  def get(url)
    JSON.parse(RestClient.get(url, headers).body)
  rescue RestClient::NotFound
    nil
  end
end
