#!/usr/bin/env ruby
# frozen_string_literal: true

require "telegram/bot"
require "fiber"

require_relative "runtime"
require_relative "dialogs/default"
require_relative "dialogs/create_project"
require_relative "dialogs/close_project"
require_relative "dialogs/reopen_project"

Telegram::Bot::Client.run(ENV.fetch("GITMAN_TELEGRAM_TOKEN")) do |bot|
  puts "Gitman on duty!"
  bot.listen(&Runtime.new(
    bot, Dialogs::Default.new(
           "/create" => proc { Dialogs::CreateProject.new.call },
           "/close" => proc { Dialogs::CloseProject.new.call },
           "/reopen" => proc { Dialogs::ReopenProject.new.call }
         )
  ).method(:main_loop))
end
