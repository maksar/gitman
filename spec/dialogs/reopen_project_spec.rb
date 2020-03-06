# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/reopen_project"
require_relative "../support/project_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::ReopenProject do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), termination).call } }
  let(:project) { ProjectInfo.new("TEST", name: "#{Services::Bitbucket::CLOSED_PROJECT_PREFIX} project") }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, nil) }

  context "when project does not exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, nil, nil) }

    it "does nothing" do
      expect(runtime.chat(payload = [project.key])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: There is no such project.
      TEXT
    end
  end

  context "when it is already open" do
    let(:project) { ProjectInfo.new("TEST", name: "Test Project") }

    context "when user does not want to reopen a repository" do
      it "does nothing" do
        expect(runtime.chat(payload = [project.key, no])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Ok, #{project.key} project exist.
          BOT: Project #{project.key} is not closed. Do you want to reopen a particalar repository? KBD: Yes, No
          USR: #{payload.shift}
          BOT: Ok then.
        TEXT
      end
    end

    context "when user wants to reopen a repository" do
      it "proceeds to continuation" do
        expect(runtime.chat(payload = [project.key, yes])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Ok, #{project.key} project exist.
          BOT: Project #{project.key} is not closed. Do you want to reopen a particalar repository? KBD: Yes, No
          USR: #{payload.shift}
        TEXT
      end
    end
  end

  context "when user wants to reopen individual repository" do
    it "proceeds to continuation" do
      expect(runtime.chat(payload = [project.key, no])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project exist.
        BOT: Do you want to reopen whole project? KBD: Yes, No
        USR: #{payload.shift}
      TEXT
    end
  end

  context "when user wants to reopen whole project" do
    let(:bitbucket) do
      DummyBitbucket.new(
        conversation, project, nil, [
          RepositoryInfo.new("normal", name: "normal_name"),
          RepositoryInfo.new("archived", name: "#{Services::Bitbucket::CLOSED_REPOSITORY_PREFIX} closed_name")
        ]
      )
    end

    it "reopens project with closed repositories" do
      expect(runtime.chat(payload = [project.key, yes])).to chat_match(<<~TEXT)
        BOT: What is Bitbucket PROJECT key?
        USR: #{payload.shift}
        BOT: Ok, #{project.key} project exist.
        BOT: Do you want to reopen whole project? KBD: Yes, No
        USR: #{payload.shift}
        SRV: reopen(#{bitbucket.project_link})
        SRV: reopen(#{bitbucket.project_link}/repos/archived)
        BOT: Project reopened! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}
      TEXT
    end
  end
end
