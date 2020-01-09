# frozen_string_literal: true

require "telegram/bot"
require_relative "../../services/auth"

require_relative "../support/dummy_store"

RSpec.describe Services::Auth do
  subject(:auth_service) { described_class.new(active_directory, store) }

  let(:uid) { rand(Float::MAX) }
  let(:phone) { " - " + rand(Float::MAX).to_s }
  let(:first_name) { "First" }
  let(:last_name) { "Last" }
  let(:name) { [last_name, first_name].join(", ") }
  let(:active_directory) { instance_double(Services::ActiveDirectory) }
  let(:contact) { Telegram::Bot::Types::Contact.new(user_id: uid, phone_number: phone, last_name: last_name, first_name: first_name) }

  before { allow(active_directory).to receive(:user_info).with(name).and_return(user) }

  shared_examples "does not authorize unknown contact" do
    it "does not authorize unknown contact" do
      expect { auth_service.authorize(contact) }.not_to change { auth_service.allowed?(uid) }.from(be_falsey)
    end
  end

  context "when user have all required attributes" do
    let(:store) { DummyStore.new(described_class::LIST_OF_ALLOWED_USERNAMES => [name]) }
    let(:user) { { uid: uid.to_s, phone: " + " + phone } }

    it_behaves_like "does not authorize unknown contact" do
      let(:user) { { uid: nil } }
    end
    it_behaves_like "does not authorize unknown contact" do
      let(:user) { { uid: uid.to_s, phone: phone + "0" } }
    end
    it_behaves_like "does not authorize unknown contact" do
      let(:user) { { uid: uid.to_s + "0", phone: phone } }
    end
    it_behaves_like "does not authorize unknown contact" do
      let(:user) { { uid: uid.to_s + "0", phone: phone + "0" } }
    end

    it_behaves_like "does not authorize unknown contact" do
      let(:store) { DummyStore.new(described_class::LIST_OF_ALLOWED_USERNAMES => []) }
    end

    it_behaves_like "does not authorize unknown contact" do
      let(:store) { DummyStore.new({}) }
    end

    it "authorizes a contact" do
      expect { auth_service.authorize(contact) }.to change { auth_service.allowed?(uid) }.to(be_truthy)
    end
  end
end
