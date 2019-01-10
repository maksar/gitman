# frozen_string_literal: true

require "net-ldap"
require "net/ldap/dn"
require "active_support/core_ext/array/access"

class ActiveDirectory
  BASE_DN = "OU=Itransition,DC=itransition,DC=corp"
  GROUPS_DN = "OU=Groups,#{BASE_DN}"
  PROJECT_GROUPS_DN = "OU=ProjectGroups,#{GROUPS_DN}"
  USERS_DN = "OU=Active,OU=Users,#{BASE_DN}"
  PARTNERS_DN = "OU=Partners,OU=Users,#{BASE_DN}"

  def initialize
    @ldap = Net::LDAP.new(
      host: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_ADDRESS"),
      port: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_PORT").to_i,
      auth: {
        method: :simple,
        username: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_USERNAME"),
        password: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_PASSWORD")
      }
    ).tap(&:bind)
  end

  def group_members(name, base = PROJECT_GROUPS_DN)
    group = find(name, base, ["member"])
    return [] unless attribute?(group, :member)

    group.member.map(&method(:dn)).flat_map do |member|
      if member.include?(", ")
        member
      else
        group_members(member, base)
      end
    end.compact.uniq
  end

  def access?(name)
    user = find(name, USERS_DN, ["memberof"]) || find(name, PARTNERS_DN, ["memberof"])
    return unless attribute?(user, :memberof)

    user.memberof.include?("CN=Git.Users.Licensed,OU=ServiceGroups,OU=Groups,#{BASE_DN}")
  end

  def manager?(name)
    user = find(name, USERS_DN, ["memberof"]) || find(name, PARTNERS_DN, ["memberof"])
    return unless attribute?(user, :memberof)

    user.memberof.any? { |group| group.include?("Managers") }
  end

  private

  def attribute?(entry, attribute)
    entry&.attribute_names&.include?(attribute)
  end

  def dn(full)
    Net::LDAP::DN.new(full).to_a.second
  end

  def find(name, base, attributes = [])
    @ldap.search(base: base, filter: Net::LDAP::Filter.eq("cn", name), attributes: attributes, size: 1).first
  end
end
