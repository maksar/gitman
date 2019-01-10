# frozen_string_literal: true

require_relative "../../dialogs/runtime"
require "telegram/bot"

class DummyRuntime < Runtime
  START = "/start"

  def initialize(conversation)
    @conversation = conversation
    super(nil)
  end

  def chat(answers)
    ([START] + answers).each do |text|
      main_loop(Telegram::Bot::Types::Message.new(chat: Telegram::Bot::Types::Chat.new(id: 0), text: text))
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
