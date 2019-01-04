# frozen_string_literal: true

class Conversation
  BOT = "BOT"
  USER = "USR"
  SERVICE = "SRV"

  attr_reader :text

  def initialize
    @text = []
  end

  def bot(message)
    add(BOT, [message[:text], answers(message[:answers]), link(message[:link])].compact.join(" "))
  end

  def user(message)
    add(USER, message)
  end

  def service(trace)
    add(SERVICE, trace)
  end

  private

  def answers(answers)
    return unless answers

    "KBD: #{answers.join(', ')}"
  end

  def link(link)
    return unless link

    "LNK: #{link}"
  end

  def add(actor, message)
    @text << [actor, message].join(": ")
  end
end
