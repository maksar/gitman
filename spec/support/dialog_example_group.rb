# frozen_string_literal: true

require "active_support/concern"
require_relative "../../dialogs/dialog"
require_relative "conversation"
require_relative "dummy_runtime"

module DialogExampleGroup
  extend ActiveSupport::Concern

  included do
    metadata[:type] = :dialog

    let(:yes) { Dialog::POSITIVE }
    let(:no) { Dialog::NEGATIVE }
    let(:conversation) { Conversation.new }
    let(:runtime) { DummyRuntime.new(conversation, dialog) }
    let(:continuation) { double(:continuation, method_missing: [:end, text: nil]) }
  end

  RSpec.configure do |config|
    config.include(self, type: :dialog, file_path: %r{spec/dialogs})
  end
end
