# frozen_string_literal: true

require_relative "../dialogs/create_project"

class Default < Dialog
  def call
    Fiber.new do |message|
      case message
      when "/create" then CreateProject.new.call
      else answer("What can I do for you?")
      end
    end
  end
end
