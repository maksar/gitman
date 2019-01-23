# frozen_string_literal: true

require_relative "../../services/active_directory"

class DummyActiveDirectory < Services::ActiveDirectory
  def initialize(group, regular, with_access, managers)
    @group = group
    @regular = regular
    @with_access = with_access
    @managers = managers
  end

  attr_reader :group, :regular, :with_access, :managers

  def group_members(name, _base = nil)
    return [] unless name == @group

    @regular + @with_access + @managers
  end

  def access?(name)
    (@with_access + @managers).include?(name)
  end

  def manager?(name)
    @managers.include?(name)
  end
end
