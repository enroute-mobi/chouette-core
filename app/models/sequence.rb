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
  validate :uniq_values_for_static_list, if: proc { |sequence| sequence.sequence_type.static_list? }

  def range_values
    "#{range_start}-#{range_end}"
  end

  #  Force empty value deletion sends by select input
  def static_list=(static_list)
    write_attribute :static_list, static_list&.reject(&:blank?)
  end

  def values(offset: 1, limit: 1000)
    if sequence_type.range_sequence?
      return [] unless range_start && range_end

      value_start = range_start + offset - 1
      value_end = value_start + limit
      value_end = range_end if value_end > range_end

      (value_start..value_end).to_a
    else
      return [] if static_list.blank?

      static_list.sort.slice(offset - 1, limit) || []
    end
  end

  def range_start_less_than_range_end
    return unless range_start && range_end
    return unless range_start >= range_end

    errors.add(:range_end, :range_start_less_than_range_end)
  end

  def uniq_values_for_static_list
    errors.add(:static_list, :uniq_values_for_static_list) if static_list.uniq != static_list
  end
end
