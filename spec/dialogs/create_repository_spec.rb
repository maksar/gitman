# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/create_project"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::CreateRepository do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), continuation).call(project.key) } }
  let(:project) { ProjectInfo.new("TEST", key: "TEST") }
  let(:repository) { RepositoryInfo.new("TEST", key: "TEST", name: "Test Repository", description: "Test Repository description", type: "normal") }

  context "when repository does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, nil, nil) }

    it "user does not want to create repository" do
      expect(runtime.chat(payload = [repository.slug, no])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to create a repository" do
      expect(runtime.chat(payload = [repository.slug, yes, repository.name, repository.description, yes])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Specify human readable repository name:
        USR: #{payload.shift}
        BOT: Specify project description:
        USR: #{payload.shift}
        BOT: We are about to create repository with name '#{repository.name}', description '#{repository.description}' KBD: #{yes}, #{no}
        USR: #{payload.shift}
        SRV: create_repository(#{repository.name}, #{repository.description})
        BOT: Name: #{repository.name}
        BOT: Description: #{repository.description}
        BOT: Repository created! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}/repos/#{repository.name.tr(' ', '-').downcase}
      TEXT
    end
  end

  context "when repository does exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

    it "shows repository details" do
      expect(runtime.chat(payload = [repository.slug])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket repository key?
        USR: #{payload.shift}
        BOT: Ok, #{repository.slug} repository already exist in #{project.key} project.
        BOT: Name: #{repository.name}
        BOT: Description: #{repository.description}
      TEXT
    end
  end
end
