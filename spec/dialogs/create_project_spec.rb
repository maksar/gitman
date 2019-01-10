# frozen_string_literal: true

require_relative "../../dialogs/dialog"
require_relative "../../dialogs/create_project"
require_relative "../support/conversation"
require_relative "../support/project_info"
require_relative "../support/dummy_runtime"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe CreateProject do
  let(:conversation) { Conversation.new }
  let(:runtime) { DummyRuntime.new(conversation) }
  let(:project) { ProjectInfo.new("TEST", key: "TEST", name: "Test Project", description: "Test Project description", type: "normal") }

  let(:continuation) { double(:continuation, method_missing: [:end, text: "END"]) }

  before { Dialog.default = described_class.new(DummyBitbucketFactory.new(bitbucket), continuation) }

  context "when project does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, nil, nil) }

    it "user does not want to create project" do
      expect(runtime.chat(payload = [project.key, Dialog::NEGATIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: There is no such project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to create a project" do
      expect(runtime.chat(payload = [project.key, Dialog::POSITIVE, project.name, project.description, Dialog::POSITIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: There is no such project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Specify project name (human readable):
        USR: #{payload.shift}
        BOT: Specify project description:
        USR: #{payload.shift}
        BOT: We are about to create project with name '#{project.name}', key '#{project.key}', description '#{project.description}' KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        SRV: create_project(#{project.name}, #{project.description})
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: Project created! LNK: #{bitbucket.projects_link}/#{project.key}
      TEXT
    end
  end

  context "when project does exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, nil) }

    it "shows project details" do
      expect(runtime.chat(payload = [project.key])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
      TEXT
    end
  end
end
