# frozen_string_literal: true

module CodesHelper
  def codes_group_by_short_name(codes)
    [].tap do |groups|
      codes.group_by { |c| c.code_space.short_name }.each do |short_name, group|
        values = group.sort_by(&:value).map(&:value).join(', ')
        groups << Group.new(short_name, values)
      end
    end
  end

  # rubocop:disable Rails/HelperInstanceVariable

  class Group
    def initialize(short_name, values)
      @short_name = short_name
      @values = values
    end
    attr_reader :short_name, :values
  end

  # rubocop:enable Rails/HelperInstanceVariable
end
