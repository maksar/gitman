# frozen_string_literal: true

require_relative "../spec_helper"
require_relative "../../dialogs/create_project"

RSpec.describe CreateProject do
  let(:runtime) { DummyRuntime.new }
  let(:project) { OpenStruct.new(key: "TEST", name: "Test Project", description: "Test Project description", type: "normal") }
  let(:repository) { OpenStruct.new(key: "TEST", name: "Test Repository", description: "Test Repository description", type: "normal") }

  before { Dialog.default = subject.method(:call) }

  context "when project and repository does not exist" do
    let(:bitbucket) { DummyBitbucket.new(runtime.conversation, nil, nil) }
    subject { described_class.new(bitbucket) }

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
        SRV: create_project(#{project.key}, #{project.name}, #{project.description})
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: Project created! LNK: #{bitbucket.projects_link}/#{project.key}
      TEXT
    end
  end

  context "when project exists and repository is not" do
    let(:bitbucket) { DummyBitbucket.new(runtime.conversation, project.to_h.stringify_keys, nil) }
    subject { described_class.new(bitbucket) }

    it "user does not want to create repository" do
      expect(runtime.chat(payload = [project.key, repository.key, Dialog::NEGATIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to create a repository" do
      expect(runtime.chat(payload = [project.key, repository.key, Dialog::POSITIVE, repository.name, repository.description, Dialog::POSITIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: There is no such repository in #{project.key} project.
        BOT: Do you want to create it? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Specify repository name (human readable):
        USR: #{payload.shift}
        BOT: Specify repository description:
        USR: #{payload.shift}
        BOT: We are about to create repository with name '#{repository.name}', key '#{repository.key}', description '#{repository.description}' KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        SRV: create_repository(#{project.key}, #{repository.key}, #{repository.name}, #{repository.description})
        BOT: Name: #{repository.name}
        BOT: Description: #{repository.description}
        BOT: Type: #{repository.type}
        BOT: Repository created! LNK: #{bitbucket.projects_link}/#{project.key}/repos/#{repository.key}
      TEXT
    end
  end

  context "when project and repository exist" do
    let(:bitbucket) { DummyBitbucket.new(runtime.conversation, project.to_h.stringify_keys, repository.to_h.stringify_keys) }
    subject { described_class.new(bitbucket) }

    it "user does not want to modify rules" do
      expect(runtime.chat(payload = [project.key, repository.key, Dialog::NEGATIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: Ok, #{repository.key} repository already exist in #{project.key} project.
        BOT: Do you want to modify the rules? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Ok then.
      TEXT
    end

    it "user wants to modify rules" do
      expect(runtime.chat(payload = [project.key, repository.key, Dialog::POSITIVE])).to match(<<~TEXT.strip)
        BOT: What is Bitbucket PROJECT name?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project already exist.
        BOT: Name: #{project.name}
        BOT: Description: #{project.description}
        BOT: Type: #{project.type}
        BOT: What is Bitbucket repository name?
        USR: #{payload.shift}
        BOT: Ok, #{repository.key} repository already exist in #{project.key} project.
        BOT: Do you want to modify the rules? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
        USR: #{payload.shift}
        BOT: Modifying rules...
      TEXT
    end
  end
end
