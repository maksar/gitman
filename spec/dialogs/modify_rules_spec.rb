# frozen_string_literal: true

require_relative "../../dialogs/dialog"
require_relative "../../dialogs/create_project"
require_relative "../support/conversation"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_runtime"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"
require_relative "../support/dummy_active_directory"

RSpec.describe ModifyRules do
  let(:conversation) { Conversation.new }
  let(:runtime) { DummyRuntime.new(conversation) }
  let(:project) { ProjectInfo.new("TEST", key: "TEST") }
  let(:repository) { RepositoryInfo.new("TEST", slug: "TEST") }
  let(:active_directory) { DummyActiveDirectory.new("GROUP", ["regular"], ["with_access"], ["manager"]) }
  let(:jira_key) { "JIRA_KEY" }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

  let(:continuation) { double(:continuation, method_missing: [:end, text: "END"]) }

  before { Dialog.default = -> { described_class.new(DummyBitbucketFactory.new(bitbucket), active_directory).call(project.key, repository.slug) } }

  it "user does not want to modify anything" do
    expect(runtime.chat(payload = [Dialog::NEGATIVE, Dialog::NEGATIVE, Dialog::NEGATIVE, Dialog::NEGATIVE, Dialog::NEGATIVE, Dialog::NEGATIVE])).to match(<<~TEXT.strip)
      BOT: Do you want set up minimal approvals and builds? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Do you want to disable force push into repository? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Do you want set up default branching model? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Do you want set up branch permissions? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Do you want set up Large Files Support? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Do you want to set up commit hooks? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: All done!
    TEXT
  end

  it "user wants to modify everything" do
    expect(runtime.chat(payload = [Dialog::POSITIVE, active_directory.group, Dialog::POSITIVE, Dialog::POSITIVE, Dialog::POSITIVE, Dialog::POSITIVE, Dialog::POSITIVE, Dialog::POSITIVE, jira_key])).to match(<<~TEXT.strip)
      BOT: Do you want set up minimal approvals and builds? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: What is the name of the project development group:
      USR: #{payload.shift}
      BOT: Group has following members: #{active_directory.regular.first}; #{active_directory.with_access.first}; #{active_directory.managers.first}
      BOT: Only following people have access to bitbucket: #{active_directory.with_access.first}; #{active_directory.managers.first}
      BOT: Only following people are not managers: #{active_directory.with_access.first}
      BOT: Setting up minimal approvals to half of the developer's teem (1) and minimal builds to 1?
      SRV: pull_requests(1, 1)
      BOT: Do you want set up default reviewers? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Adding default reviewers.
      SRV: default_reviewers(["with_access"], 1)
      BOT: Do you want to disable force push into repository? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      SRV: enable_force_push()
      BOT: Do you want set up default branching model? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Setting up default branching model.
      SRV: branch_model()
      BOT: Do you want set up branch permissions? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Setting branch permissions.
      SRV: branch_permissions()
      BOT: Do you want set up Large Files Support? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: Enabling Large Files Support.
      SRV: large_files_support()
      BOT: Do you want to set up commit hooks? KBD: #{Dialog::POSITIVE}, #{Dialog::NEGATIVE}
      USR: #{payload.shift}
      BOT: What is JIRA project key?
      USR: #{payload.shift}
      BOT: Enabling commit hooks - jira task prefix, proper author name and email.
      SRV: commit_hooks(JIRA_KEY)
      BOT: All done!
    TEXT
  end
end
