# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  add_group "Dialogs", "dialogs/"
  add_group "Services", "services/"
  add_group "Specs", "spec/"
end
