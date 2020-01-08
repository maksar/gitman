# frozen_string_literal: true

require "net-ldap"
require "net/ldap/dn"
require "active_support/core_ext/array/access"
require "active_support/core_ext/object/try"

module Services
  class ActiveDirectory
    BASE_DN = "OU=Itransition,DC=itransition,DC=corp"
    GROUPS_DN = "OU=Groups,#{BASE_DN}"
    PROJECT_GROUPS_DN = "OU=ProjectGroups,#{GROUPS_DN}"
    USERS_DN = "OU=Active,OU=Users,#{BASE_DN}"
    PARTNERS_DN = "OU=Partners,OU=Users,#{BASE_DN}"
    FREELANCERS_DN = "OU=Freelancers,OU=Users,#{BASE_DN}"

    TECHNICAL_COORDINATORS_GROUP = "Technical Coordinators"

    def initialize
      @ldap = Net::LDAP.new(
        host: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_ADDRESS"), port: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_PORT").to_i,
        auth: { method: :simple, username: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_USERNAME"), password: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_PASSWORD") },
        encryption: { method: :simple_tls, tls_options: { security_level: 1, ca_file: ENV.fetch("GITMAN_ACTIVE_DIRECTORY_CERTIFICATE"), verify_mode: OpenSSL::SSL::VERIFY_PEER } }
      ).tap(&:bind)
    end

    def group_members(name, base = PROJECT_GROUPS_DN)
      group = find(name, base, ["member"])
      return [] unless attribute(group, :member)

      group.member.map(&method(:dn)).flat_map do |member|
        if member.include?(", ")
          user(member, "dn") && display_name(member)
        else
          group_members(member, base)
        end
      end.compact.uniq
    end

    def access?(name)
      user_groups(name).include?("CN=Git.Users.Licensed,OU=ServiceGroups,OU=Groups,#{BASE_DN}")
    end

    def manager?(name)
      user_groups(name).any? { |group| group.include?("Managers") }
    end

    def display_name(name)
      user = user(name, %w[displayName])
      attribute(user, :displayName).try(&:first) || dn(user.dn)
    end

    def user_info(name)
      user = user(name, %w[extensionAttribute9 mobile])
      { phone: attribute(user, :mobile).try(&:first), uid: attribute(user, :extensionAttribute9).try(&:first) }
    end

    def user_groups(name)
      attribute(user(name, ["memberof"]), :memberof)
    end

    def technical_coordinators
      group_members(TECHNICAL_COORDINATORS_GROUP, Services::ActiveDirectory::GROUPS_DN)
    end

    private

    def user(name, attributes)
      find(name, USERS_DN, attributes) || find(name, PARTNERS_DN, attributes) || find(name, FREELANCERS_DN, attributes)
    end

    def attribute(entry, attribute)
      (entry || {})[attribute]
    end

    def dn(full)
      Net::LDAP::DN.new(full).to_a.second
    end

    def find(name, base, attributes = [])
      filter = Net::LDAP::Filter.eq("cn", name) | Net::LDAP::Filter.eq("displayName", name)
      @ldap.search(base: base, filter: filter, attributes: attributes, size: 1).first
    end
  end
end
