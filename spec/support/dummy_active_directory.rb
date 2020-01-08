# frozen_string_literal: true

require_relative "../../services/active_directory"

class DummyActiveDirectory < Services::ActiveDirectory
  def initialize(group, regular, with_access, managers, technical_coordinators)
    @group = group
    @regular = regular
    @with_access = with_access
    @managers = managers
    @technical_coordinators = technical_coordinators
  end

  attr_reader :technical_coordinators

  def group_members(name, _base = nil)
    return [] unless name == @group

    @regular + @with_access + @managers + @technical_coordinators
  end

  def access?(name)
    (@with_access + @managers + @technical_coordinators).include?(name)
  end

  def manager?(name)
    @managers.include?(name)
  end
end
