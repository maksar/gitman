# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/create_project"
require_relative "../support/project_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::CreateProject do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), termination).call } }
  let(:project) { ProjectInfo.new("TEST", name: "Test Project", description: "Test Project description", type: "normal") }

  context "when project does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, nil, nil) }

    it "user does not want to create project" do
      expect(runtime.chat(payload = [project.key, no])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: There is no such project.
        BOT: Do you want to create it? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to create a project" do
      expect(runtime.chat(payload = [project.key, yes, project.name, project.description, yes])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: There is no such project.
        BOT: Do you want to create it? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Specify project name (human readable):
        USR: #{payload.shift}
        BOT: Specify project description:
        USR: #{payload.shift}
        BOT: We are about to create project with name '#{project.name}', key '#{project.key}', description '#{project.description}' KBD: #{yes}, #{no}
        USR: #{payload.shift}
        SRV: create_project(#{project.name}, #{project.description})
        BOT: Name: #{project.name}
        BOT: Type: #{project.type}
        BOT: Description: #{project.description}
        BOT: Project created! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}
      TEXT
    end
  end

  context "when project does exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, nil) }

    it "shows project details" do
      expect(runtime.chat(payload = [project.key])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Type: #{project.type}
        BOT: Description: #{project.description}
      TEXT
    end

    context "when does not have a description" do
      before { project[:description] = nil }

      it "shows project details with no description" do
        expect(runtime.chat(payload = [project.key])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Ok, #{project.key} project already exist.
          BOT: Name: #{project.name}
          BOT: Type: #{project.type}
        TEXT
      end
    end
  end
end
