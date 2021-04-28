# frozen_string_literal: true

require "telegram/bot"
require "active_support/core_ext/object/try"

require_relative "services/auth"

class Runtime
  def initialize(bot, default_dialog, auth = Services::Auth.new)
    @bot = bot
    @dialogs = Hash.new { default_dialog.call }
    @auth = auth
  end

  def main_loop(message)
    return self unless known_user?(message)

    @dialogs[message.chat.id] = listen(message.chat.id, message.text, @dialogs[message.chat.id])
    self
  end

  private

  def known_user?(message)
    return false unless authorize_user(message)

    unless @auth.allowed?(message.from.id)
      print(message.chat.id, text: "I will not speak to strangers.", contact: "Give me your contact")
      return false
    end
    true
  end

  def authorize_user(message)
    message&.contact.try do |contact|
      if (person = @auth.authorize(contact))
        print(message.chat.id, text: "I recognize you, #{person}!")
      else
        print(message.chat.id, text: "I cannot recognize you. Please, add correct first name, last name and phone to match AD.", contact: "Give me your contact")
        return false
      end
    end
    true
  end

  def listen(chat, text, dialog)
    return reset(chat, "Ok, then.") if text == "/cancel"

    case (result = dialog.resume(text))
    in [:question | :statement, payload]
      print(chat, payload)
      decide(chat, dialog, result, text)
    in Fiber then listen(chat, text, result)
    else decide(chat, dialog, result, text)
    end
  rescue StandardError => e
    reset(chat, "Something bad happens: #{e}\n#{e.message}\n#{e.backtrace}")
  end

  def reset(chat, text)
    print(chat, text: text)
    @dialogs.default(nil)
  end

  def decide(chat, dialog, result, text)
    case result
    in [:question, *] then dialog
    in [:statement, *] then listen(chat, text, dialog)
    in :end then listen(chat, text, @dialogs.default(nil))
    in command then print(chat, text: "Unknown internal command: #{command}")
    end
  end

  def print(chat, payload)
    @bot.api.send_message(chat_id: chat, text: payload.fetch(:text), reply_markup: reply_markup(payload))
  end

  def reply_markup(payload)
    case payload
    in { contact: } then Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [Telegram::Bot::Types::KeyboardButton.new(text: contact, request_contact: true)], one_time_keyboard: true)
    in { link:, text: } then Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [Telegram::Bot::Types::InlineKeyboardButton.new(text: text, url: link)])
    in { answers: } then Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
    else Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    end
  end
end
