# frozen_string_literal: true

require "active_support/concern"

require_relative "../../dialogs/base"
require_relative "conversation"
require_relative "dummy_runtime"
require_relative "dummy_continuation"

module DialogExampleGroup
  extend ActiveSupport::Concern

  included do
    metadata[:type] = :dialog

    let(:yes) { Dialogs::Base::POSITIVE }
    let(:no) { Dialogs::Base::NEGATIVE }
    let(:conversation) { Conversation.new }
    let(:runtime) { DummyRuntime.new(conversation, dialog) }
    let(:termination) { DummyContinuation.new }
  end

  RSpec.configure do |config|
    config.include(self, type: :dialog, file_path: %r{spec/dialogs})
  end
end

RSpec::Matchers.define :chat_match do |expected|
  match do |actual|
    actual.strip == expected.strip
  end
end
