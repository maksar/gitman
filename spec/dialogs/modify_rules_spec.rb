# frozen_string_literal: true

require_relative "../support/dialog_example_group"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"
require_relative "../support/dummy_active_directory"

RSpec.describe ModifyRules do
  let(:project) { ProjectInfo.new("TEST", key: "TEST") }
  let(:repository) { RepositoryInfo.new("TEST", slug: "TEST") }
  let(:active_directory) { DummyActiveDirectory.new("GROUP", ["regular"], ["with_access"], ["manager"]) }
  let(:jira_key) { "JIRA_KEY" }
  let(:technical_coordinator) { "technical.coordinator" }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

  before { Dialog.default = -> { described_class.new(DummyBitbucketFactory.new(bitbucket), active_directory).call(project.key, repository.slug) } }

  it "user does not want to modify anything" do
    expect(runtime.chat(payload = [no, no, no, no, no, no, no])).to match(<<~TEXT.strip)
      BOT: Do you want to set up permissions for the project? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to set up minimal approvals and builds? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to set up default branching model? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to set up branch permissions? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to disable force push into repository? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to set up Large Files Support? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Do you want to set up commit hooks? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: All done!
    TEXT
  end

  it "user wants to modify everything" do
    expect(runtime.chat(payload = [yes, active_directory.group, technical_coordinator, yes, yes, yes, yes, yes, yes, yes, jira_key])).to match(<<~TEXT.strip)
      BOT: Do you want to set up permissions for the project? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: What is the name of the project development group:
      USR: #{payload.shift}
      BOT: Granted write access for the group GROUP.
      SRV: group_write_access(#{active_directory.group})
      BOT: There is no technical coordinators in the #{active_directory.group} group.
      BOT: Username of the technical coordinator:
      USR: #{payload.shift}
      BOT: Granted admin access for the people #{technical_coordinator}.
      SRV: personal_admin_access([#{technical_coordinator}])
      BOT: Do you want to set up minimal approvals and builds? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Group #{active_directory.group} has following members: #{active_directory.regular.first}; #{active_directory.with_access.first}; #{active_directory.managers.first}
      BOT: Only following people have access to bitbucket: #{active_directory.with_access.first}; #{active_directory.managers.first}
      BOT: Only following people are not managers: #{active_directory.with_access.first}
      BOT: Setting up minimal approvals to half of the developer's team (1) and minimal builds to 1?
      SRV: pull_requests(1, 1)
      BOT: Do you want to set up default reviewers? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Adding default reviewers.
      SRV: default_reviewers([#{active_directory.with_access.first}], 1)
      BOT: Do you want to set up default branching model? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Setting up default branching model.
      SRV: branch_model()
      BOT: Do you want to set up branch permissions? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Setting branch permissions.
      SRV: branch_permissions()
      BOT: Do you want to disable force push into repository? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      SRV: enable_force_push()
      BOT: Do you want to set up Large Files Support? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: Enabling Large Files Support.
      SRV: large_files_support()
      BOT: Do you want to set up commit hooks? KBD: #{yes}, #{no}
      USR: #{payload.shift}
      BOT: What is JIRA project key?
      USR: #{payload.shift}
      BOT: Enabling commit hooks - jira task prefix, proper author name and email.
      SRV: commit_hooks(JIRA_KEY)
      BOT: All done!
    TEXT
  end
end
