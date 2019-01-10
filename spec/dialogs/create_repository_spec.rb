# frozen_string_literal: true

require_relative "../../dialogs/dialog"
require_relative "../../dialogs/create_project"
require_relative "../support/conversation"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_runtime"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe CreateRepository do
  let(:conversation) { Conversation.new }
  let(:runtime) { DummyRuntime.new(conversation) }
  let(:project) { ProjectInfo.new("TEST", key: "TEST") }
  let(:repository) { RepositoryInfo.new("TEST", key: "TEST", name: "Test Repository", description: "Test Repository description", type: "normal") }

  let(:continuation) { double(:continuation, method_missing: [:end, text: "END"]) }

  before { Dialog.default = -> { described_class.new(DummyBitbucketFactory.new(bitbucket), continuation).call(project.key) } }

  context "when repository does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, nil, nil) }

    it "user does not want to create repository" do
      expect(runtime.chat(payload = [repository.slug, Dialog::NEGATIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to create a repository" do
      expect(runtime.chat(payload = [repository.slug, Dialog::POSITIVE, repository.name, Dialog::POSITIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Specify repository name (human readable):
        USR: #{payload.shift}
        BOT: We are about to create repository with name '#{repository.name}', slug '#{repository.slug}' KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        SRV: create_repository(#{repository.name})
        BOT: Name: #{repository.name}
        BOT: Repository created! LNK: #{bitbucket.projects_link}/#{project.key}/repos/#{repository.slug}
      TEXT
    end
  end

  context "when repository does exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

    it "shows repository details" do
      expect(runtime.chat(payload = [repository.slug])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: Ok, #{repository.slug} repository already exist in #{project.key} project.
        BOT: Name: #{repository.name}
      TEXT
    end
  end
end
