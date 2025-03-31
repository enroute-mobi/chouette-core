# frozen_string_literal: true

module FlexibleStopAreaHelper
  def join_members(members)
    JoinMembers.new(
      t('activerecord.attributes.flexible_area_membership.member_id'),
      members.map(&:name).join(', ')
    )
  end

  class JoinMembers
    def initialize(label, values)
      @label = label
      @values = values
    end
    attr_reader :label, :values
  end
end






