# frozen_string_literal: true

require "yaml/store"
require_relative "services/active_directory"

class Auth
  def initialize(active_directory = ActiveDirectory.new)
    @active_directory = active_directory
    @store = YAML::Store.new("users.yml")
  end

  def authorize(contact)
    @store.transaction do
      @store[contact.user_id.to_s] = name(contact) if valid?(contact)
    end
  end

  def allowed?(uid)
    @store.transaction do
      @store[uid.to_s]
    end
  end

  private

  def valid?(contact)
    user_info = @active_directory.user_info(name(contact))

    @store.fetch("allowed", []).include?(name(contact)) &&
      user_info.fetch(:uid) == contact.user_id.to_s &&
      user_info.fetch(:phone).delete(" \\-+") == contact.phone_number.delete(" \\-+")
  end

  def name(contact)
    [contact.last_name, contact.first_name].join(", ")
  end
end
