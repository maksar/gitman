# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/close_project"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::CloseRepository do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket)).call(project.key) } }
  let(:project) { ProjectInfo.new("PROJ") }
  let(:repository) { RepositoryInfo.new("REPO", name: "Test Repository") }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, repository, [RepositoryInfo.new("normal", name: "normal_name")]) }

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

  context "when repository is already closed" do
    let(:repository) { RepositoryInfo.new("archived", name: "#{Services::Bitbucket::CLOSED_REPOSITORY_PREFIX} closed_name") }

    it "does nothing" do
      expect(runtime.chat(payload = [repository.slug])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: Repository archived is already closed.
      TEXT
    end
  end

  it "closes repository" do
    expect(runtime.chat(payload = [repository.slug])).to chat_match(<<~TEXT)
      BOT: What is Bitbucket repository key?
      USR: #{payload.shift}
      BOT: Ok, #{repository.slug} repository exist in #{project.key} project.
      SRV: close('CLOSED_', #{bitbucket.project_link}/repos/#{repository.slug})
      BOT: Repository closed! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}/repos/#{repository.slug}
    TEXT
  end

  context "when all repositories in a project are closed" do
    let(:bitbucket) do
      DummyBitbucket.new(
        conversation, project, repository, [
          RepositoryInfo.new("archived", name: "#{Services::Bitbucket::CLOSED_REPOSITORY_PREFIX} closed_name")
        ]
      )
    end

    context "when user wants to keep the project open" do
      it "keeps the project opened" do
        expect(runtime.chat(payload = [repository.slug, no])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket repository key?
          USR: #{payload.shift}
          BOT: Ok, #{repository.slug} repository exist in #{project.key} project.
          SRV: close('CLOSED_', #{bitbucket.project_link}/repos/#{repository.slug})
          BOT: Repository closed! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}/repos/#{repository.slug}
          BOT: All repositories in #{project.key} project are closed. Do you alse want to close the project itself? KBD: Yes, No
          USR: #{payload.shift}
          BOT: Ok then.
        TEXT
      end
    end

    context "when user wants to also close a project" do
      it "closes a project" do
        expect(runtime.chat(payload = [repository.slug, yes])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket repository key?
          USR: #{payload.shift}
          BOT: Ok, #{repository.slug} repository exist in #{project.key} project.
          SRV: close('CLOSED_', #{bitbucket.project_link}/repos/#{repository.slug})
          BOT: Repository closed! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}/repos/#{repository.slug}
          BOT: All repositories in #{project.key} project are closed. Do you alse want to close the project itself? KBD: Yes, No
          USR: #{payload.shift}
          SRV: close('[Closed] ', #{bitbucket.project_link})
          BOT: Project closed! LNK: #{bitbucket.project_link(Services::Bitbucket::BROWSER_PREFIX)}
        TEXT
      end
    end
  end
end
