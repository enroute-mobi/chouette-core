# frozen_string_literal: true

class Sequence < ApplicationModel
  extend Enumerize

  belongs_to :workbench, optional: false, class_name: 'Workbench'

  enumerize :sequence_type, in: %i[range_sequence static_list], default: :range_sequence, scope: true

  validates :name, presence: true
  validates :range_start, :range_end, numericality: { only_integer: true }, allow_blank: false, if: proc { |sequence|
                                                                                                      sequence.sequence_type.range_sequence?
                                                                                                    }
  validate :range_start_less_than_range_end, if: proc { |sequence| sequence.sequence_type.range_sequence? }

  def range_values
    "#{range_start}-#{range_end}"
  end

  #  Force empty value deletion sends by select input
  def static_list=(static_list)
    write_attribute :static_list, static_list&.reject(&:blank?)
  end

  def values(offset: 1, limit: 1000)
    values = []
    if sequence_type.range_sequence?
      return [] unless range_start && range_end

      value_start = offset
      value_end = value_start + limit
      value_end = range_end if value_end > range_end
      values = (value_start..value_end).to_a
    else
      return [] if static_list.blank?

      values = static_list.sort.slice(offset - 1, limit) || []
    end
    values
  end

  def range_start_less_than_range_end
    return unless range_start && range_end
    return unless range_start >= range_end

    errors.add(:range_end, :range_start_less_than_range_end)
  end
end
