# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/reopen_repository"
require_relative "../support/project_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::ReopenRepository do
  let(:project) { ProjectInfo.new("PROJ") }
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), termination).call(project.key) } }
  let(:repository) { RepositoryInfo.new("archived", name: "#{Services::Bitbucket::CLOSED_REPOSITORY_PREFIX} closed_name") }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

  context "when repository does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, nil) }

    it "user does not want to create repository" do
      expect(runtime.chat(payload = [repository.slug])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
      TEXT
    end
  end

  context "when repository is already opened" do
    let(:repository) { RepositoryInfo.new("REPO", name: "Test Repository") }

    it "does nothing" do
      expect(runtime.chat(payload = [repository.slug])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: Repository #{repository.slug} is not closed.
      TEXT
    end
  end

  context "when repository is closed" do
    it "reopens repository and a project" do
      expect(runtime.chat(payload = [repository.slug])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: Ok, closed #{repository.slug} repository exist in #{project.key} project.
        SRV: reopen(#{bitbucket.project_link}/repos/#{repository.slug})
        SRV: reopen(#{bitbucket.project_link})
        BOT: Repository and a project reopened! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}/repos/#{repository.slug}
      TEXT
    end
  end
end
