#!/usr/bin/env ruby
# frozen_string_literal: true

require "telegram/bot"
require "fiber"

require_relative "dialogs/create_project"
require_relative "dialogs/runtime"

Dialog.default = Class.new(Dialog) do
  def call
    Fiber.new do |message|
      case message
      when "/create" then CreateProject.new.call
      else answer("What can I do for you?")
      end
    end
  end
end.new

Telegram::Bot::Client.run(ENV.fetch("GITMAN_TELEGRAM_TOKEN")) do |bot|
  puts "Gitman on duty!"
  bot.listen(&Runtime.new(bot).method(:main_loop))
end
