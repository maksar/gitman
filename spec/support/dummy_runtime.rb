# frozen_string_literal: true

require_relative "../../runtime"
require_relative "dummy_auth"
require "telegram/bot"

class DummyRuntime < Runtime
  START = "/start"

  def initialize(conversation, dialog)
    @conversation = conversation
    super(nil, dialog, DummyAuth.new)
  end

  def chat(answers)
    ([START] + answers).each do |text|
      main_loop(Telegram::Bot::Types::Message.new(from: Telegram::Bot::Types::User.new(id: 0), chat: Telegram::Bot::Types::Chat.new(id: 0), text: text))
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

  def decide(chat, dialog, result, text)
    return if result == :end

    super
  end

  def print(_chat, message)
    @conversation.bot(message) if message.fetch(:text)
  end
end
