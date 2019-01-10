# frozen_string_literal: true

require_relative "dialog"
require "active_support/core_ext/object/try"
require "telegram/bot"

class Runtime
  def initialize(bot)
    @bot = bot
    @dialogs = Hash.new { Dialog.default.call }
  end

  def main_loop(message)
    @dialogs[message.chat.id] = listen(message.chat.id, message.text, @dialogs[message.chat.id])
    self
  end

  private

  def listen(chat, text, dialog)
    result = dialog.resume(text)

    return listen(chat, text, result) if result.is_a?(Fiber)

    print(chat, result.last)
    decide(chat, dialog, result, text)
  rescue StandardError => error
    print(chat, text: "Something bad happens: #{error}\n#{error.message}\n#{error.backtrace}")
    Dialog.default.call
  end

  def decide(chat, dialog, result, text)
    case result.first
    when :question then dialog
    when :statement then listen(chat, text, dialog)
    when :end then nil
    else print(chat, text: "Unknown internal command: #{result.first}.")
    end
  end

  def print(chat, payload)
    @bot.api.send_message(chat_id: chat, text: payload.fetch(:text), reply_markup: reply_markup(payload))
  end

  def reply_markup(payload)
    payload[:link].try do |link|
      Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [Telegram::Bot::Types::InlineKeyboardButton.new(text: payload.fetch(:text), url: link)])
    end ||
      payload[:answers].try do |answers|
        Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
      end ||
      Telegram::Bot::Types::ReplyKeyboardMarkup.new(remove_keyboard: true)
  end
end
