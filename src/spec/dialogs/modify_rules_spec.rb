# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../../dialogs/modify_rules"
require_relative "../support/project_info"
require_relative "../support/repository_info"
require_relative "../support/dummy_bitbucket_factory"
require_relative "../support/dummy_bitbucket"
require_relative "../support/dummy_active_directory"

RSpec.describe Dialogs::ModifyRules do
  let(:dialog) { proc { described_class.new(DummyBitbucketFactory.new(bitbucket), active_directory).call(project.key, repository.slug) } }
  let(:project) { ProjectInfo.new("PROJ") }
  let(:repository) { RepositoryInfo.new("REPO") }
  let(:technical_coordinator) { "technical.coordinator" }
  let(:regular_user) { "regular" }
  let(:user_with_access) { "with_access" }
  let(:manager) { "manager" }
  let(:group) { "GROUP" }
  let(:non_existent_group) { "#{group}MISSING" }
  let(:bitbucket) { DummyBitbucket.new(conversation, project, repository) }

  context "when active directory doesn't matter" do
    let(:active_directory) { DummyActiveDirectory.new(group, [], [], [], []) }

    it "user does not want to modify anything" do
      expect(runtime.chat(payload = [no, no, no, no, no, no, no])).to chat_match(<<~TEXT)
        BOT: Do you want to set up permissions for the repository? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Do you want to set up minimal approvals? KBD: #{yes}, #{no}
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
  end

  context "when active directory group does not contain technical coordinator" do
    let(:active_directory) { DummyActiveDirectory.new(group, [regular_user], [user_with_access], [manager], []) }
    let(:builds) { "1" }
    let(:jira_key) { "JIRA_KEY" }

    it "user wants to modify everything" do
      expect(runtime.chat(payload = [yes, non_existent_group, group, technical_coordinator, yes, yes, builds, yes, yes, yes, yes, yes, yes, jira_key])).to chat_match(<<~TEXT)
        BOT: Do you want to set up permissions for the repository? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: What is the name of the project development group:
        USR: #{payload.shift}
        BOT: Cannot find any members in group #{non_existent_group}.
        BOT: What is the name of the project development group:
        USR: #{payload.shift}
        SRV: group_write_access(#{group})
        BOT: Granted write access for the group #{group}.
        BOT: There are no technical coordinators in the #{group} group.
        BOT: Username of the technical coordinator:
        USR: #{payload.shift}
        SRV: personal_admin_access([#{technical_coordinator}])
        BOT: Granted admin access for the people #{technical_coordinator}.
        BOT: Do you want to set up minimal approvals? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Group #{group} has following members: #{[regular_user, user_with_access, manager].join('; ')}
        BOT: Only following people have access to bitbucket: #{[user_with_access, manager].join('; ')}
        BOT: Only following people are not managers: #{user_with_access}
        BOT: Do you want to set up minimal builds? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: What is the number of builds you want to require:
        USR: #{payload.shift}
        BOT: Setting up minimal approvals to half of the developer's team (1) and minimal builds to #{builds}.
        SRV: pull_requests(1, #{builds})
        BOT: Do you want to set up default reviewers? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Adding default reviewers.
        SRV: default_reviewers([#{user_with_access}], 1)
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
        SRV: commit_hooks(#{jira_key})
        BOT: All done!
      TEXT
    end
  end

  context "when active directory group contain technical coordinator" do
    let(:active_directory) { DummyActiveDirectory.new(group, [regular_user], [user_with_access], [manager], [technical_coordinator]) }

    it "user wants to modify minimal approvals" do
      expect(runtime.chat(payload = [yes, group, yes, no, no, no, no, no, no, no])).to chat_match(<<~TEXT)
        BOT: Do you want to set up permissions for the repository? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: What is the name of the project development group:
        USR: #{payload.shift}
        SRV: group_write_access(#{group})
        BOT: Granted write access for the group #{group}.
        SRV: personal_admin_access([#{technical_coordinator}])
        BOT: Granted admin access for the people #{technical_coordinator}.
        BOT: Do you want to set up minimal approvals? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Group #{group} has following members: #{[regular_user, user_with_access, manager, technical_coordinator].join('; ')}
        BOT: Only following people have access to bitbucket: #{[user_with_access, manager, technical_coordinator].join('; ')}
        BOT: Only following people are not managers: #{[user_with_access, technical_coordinator].join('; ')}
        BOT: Do you want to set up minimal builds? KBD: #{yes}, #{no}
        USR: #{payload.shift}
        BOT: Setting up minimal approvals to half of the developer's team (1) and minimal builds to 0.
        SRV: pull_requests(1, 0)
        BOT: Do you want to set up default reviewers? KBD: #{yes}, #{no}
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
  end
end
