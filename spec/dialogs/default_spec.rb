# frozen_string_literal: true

require_relative "../support/dialog_example_group"

require_relative "../support/dialogs/endless"
require_relative "../support/dialogs/broken"
require_relative "../support/dialogs/unknown_command"

require_relative "../../dialogs/default"

RSpec.describe Dialogs::Default do
  context "when continuation ends" do
    let(:dialog) { proc { described_class.new({}).call } }

    it "does not react on unknown commands" do
      expect(runtime.chat(payload = ["/unknown"])).to chat_match(<<~TEXT)
        BOT: What can I do for you?
        USR: #{payload.shift}
      TEXT
    end
  end

  context "when continuation cycles" do
    let(:dialog) { proc { Dialogs::Endless.new({}).call } }

    it "continues to ask questions" do
      expect(runtime.chat(payload = ["/whatever"])).to chat_match(<<~TEXT)
        BOT: What can I do for you?
        USR: #{payload.shift}
        BOT: What can I do for you?
      TEXT
    end
  end

  context "when continuation produces unknown command" do
    let(:dialog) { proc { Dialogs::UnknownCommand.new({}).call } }

    it "continues reports about unknown command" do
      expect(runtime.chat(payload = ["/unknown"])).to chat_match(<<~TEXT)
        BOT: What can I do for you?
        USR: #{payload.shift}
        BOT: Unknown internal command: unknown
      TEXT
    end
  end

  context "when continuation fails" do
    let(:dialog) { proc { Dialogs::Broken.new({}).call } }

    it "fails and prints error" do
      expect(runtime.chat(payload = ["/broken"]).lines[..2].join).to chat_match(<<~TEXT)
        BOT: What can I do for you?
        USR: #{payload.shift}
        BOT: Something bad happens: uncaught throw StandardError
      TEXT
    end
  end
end
