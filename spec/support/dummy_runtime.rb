# frozen_string_literal: true

require_relative "../../dialogs/runtime"
require_relative "conversation"

class DummyRuntime < Runtime
  START = "/start"

  attr_reader :conversation

  def initialize
    @conversation = Conversation.new
    super(nil)
  end

  def chat(answers)
    ([START] + answers).each do |text|
      main_loop(OpenStruct.new(chat: OpenStruct.new(id: 0), text: text))
    end
    @conversation.text.join("\n")
  end

  def main_loop(message)
    @conversation.user(message.text) unless message.text == START
    super
  end

  def logged_as?(chat)
    @conversation.text == chat.lines.map(&:strip)
  end

  private

  def print(_chat, message)
    @conversation.bot(message)
  end
end
