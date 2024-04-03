# frozen_string_literal: true

class Sequence < ApplicationModel
  extend Enumerize

  belongs_to :workbench, optional: false, class_name: 'Workbench'

  validates :name, :sequence_type, presence: true

  enumerize :sequence_type, in: %i[range_sequence static_list], default: :range_sequence, scope: true

  validates :range_start, :range_end, numericality: { only_integer: true }, allow_blank: false

  validate :range_start_less_than_range_end

  # attribute :static_list, ::Sequence::Type.new

  # def static_list
  #   self.static_list.join(',')
  # end

  def range_values
    "#{range_start}-#{range_end}"
  end

  def values(offset: 1, limit: 1000)
    return unless range_start && range_end

    value_start = range_start + (offset - 1) * limit
    value_end = value_start + limit - 1
    value_end = range_end if value_end > range_end

    (value_start..value_end).to_a
  end

  def range_start_less_than_range_end
    return unless range_start && range_end

    return unless range_start >= range_end

    errors.add(:range_end, :range_start_less_than_range_end)
  end

  class Type < ::ActiveRecord::Type::Value
    def cast(value)
      return if value.blank?
      value.first.split(',') if value.is_a?(String)
    end
    def serialize(value)
      return if value.blank?
      value.to_s
    end
  end
end
