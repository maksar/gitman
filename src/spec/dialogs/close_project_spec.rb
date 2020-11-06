# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/close_project"
require_relative "../support/project_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"

RSpec.describe Dialogs::CloseProject do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), termination).call } }
  let(:project) { ProjectInfo.new("TEST", name: "Test Project") }

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

  context "when project does exist" do
    let(:bitbucket) { DummyBitbucket.new(conversation, project, nil) }

    context "when it is already closed" do
      let(:project) { ProjectInfo.new("TEST", name: "#{Services::Bitbucket::CLOSED_PROJECT_PREFIX} Test Project") }

      it "reports that project is already closed" do
        expect(runtime.chat(payload = [project.key])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Project #{project.key} is already closed.
        TEXT
      end
    end

    context "when user wants to close individual repository" do
      it "proceeds to continuation" do
        expect(runtime.chat(payload = [project.key, no])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Ok, #{project.key} project exist.
          BOT: Do you want to close whole project? KBD: Yes, No
          USR: #{payload.shift}
        TEXT
      end
    end

    context "when user wants to close whole project" do
      let(:bitbucket) do
        DummyBitbucket.new(
          conversation, project, nil, [
            RepositoryInfo.new("archived", name: "#{Services::Bitbucket::CLOSED_REPOSITORY_PREFIX} closed_name"),
            RepositoryInfo.new("normal", name: "normal_name")
          ]
        )
      end

      it "closes project with open repositories" do
        expect(runtime.chat(payload = [project.key, yes])).to chat_match(<<~TEXT)
          BOT: What is Bitbucket PROJECT key?
          USR: #{payload.shift}
          BOT: Ok, #{project.key} project exist.
          BOT: Do you want to close whole project? KBD: Yes, No
          USR: #{payload.shift}
          SRV: close('[Closed] ', #{bitbucket.project_link})
          SRV: close('CLOSED_', #{bitbucket.project_link}/repos/normal)
          BOT: Project closed! LNK: #{bitbucket.projects_link(Services::Bitbucket::BROWSER_PREFIX)}/#{project.key}
        TEXT
      end
    end
  end
end
