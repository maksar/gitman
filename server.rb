# frozen_string_literal: true

require "telegram/bot"
require "fiber"

require_relative "dialogs/echo"
require_relative "dialogs/greeter"
require_relative "dialogs/create_project"
require_relative "dialogs/runtime"

Dialog.default = Class.new(Dialog) do
  def call
    Fiber.new do |message|
      case message
      when "/test" then CreateProject.new.call
      when "/greet" then Greeter.new.call
      when %r{/greet (.*)} then Greeter.new.call(Regexp.last_match(1))
      when %r{/echo (.*)} then Echo.new.call(Regexp.last_match(1))
      else answer("What can I do for you?")
      end
    end
  end
end.new

Telegram::Bot::Client.run(ENV.fetch("GITMAN_TELEGRAM_TOKEN")) do |bot|
  bot.listen(&Runtime.new(bot).method(:main_loop))
end
