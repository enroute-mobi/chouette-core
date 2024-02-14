class AbstractCode < ActiveRecord::Base
  self.abstract_class = true

  acts_as_copy_target

  belongs_to :code_space, required: true
  belongs_to :resource, polymorphic: true, required: true

  validates :value, presence: true

  validate :allow_multiple_values, :value_uniqueness

  def value_uniqueness
    values = resource.codes.map { |code| [code.value, code.code_space_id] }
    return if values == values.uniq

    errors.add(:value, :duplicate_values_in_codes)
  end

  def allow_multiple_values
    debugger
    return if code_space.allow_multiple_values

    code_spaces = resource.codes.map(&:code_space_id)
    return if code_spaces.size == code_spaces.uniq.size

    errors.add(:value, :duplicate_code_spaces_in_codes, code_space: code_space.short_name)
  end
end