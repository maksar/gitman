#!/usr/bin/env ruby
# frozen_string_literal: true

require "telegram/bot"
require "fiber"

require_relative "dialogs/create_project"
require_relative "dialogs/runtime"
require_relative "dialogs/default"

Telegram::Bot::Client.run(ENV.fetch("GITMAN_TELEGRAM_TOKEN")) do |bot|
  puts "Gitman on duty!"
  bot.listen(&Runtime.new(bot, Default.new).method(:main_loop))
end
