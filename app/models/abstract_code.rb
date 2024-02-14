class AbstractCode < ActiveRecord::Base
  self.abstract_class = true

  acts_as_copy_target

  belongs_to :code_space, required: true
  belongs_to :resource, polymorphic: true, required: true

  validates :value, presence: true

  validate :allow_multiple_values, :value_uniqueness

  private

  delegate :codes, to: :resource, allow_nil: true

  def value_uniqueness
    return unless duplicated_values.include? [code_space_id, value]

    errors.add(:value, :duplicate_values_in_codes)
  end

  def allow_multiple_values
    return unless duplicated_code_spaces.include? code_space_id

    errors.add(:value, :duplicate_code_spaces_in_codes, code_space: code_space.short_name)
  end

  def duplicated_values
    return [] unless codes

    codes
      .group_by { |code| [code.code_space_id, code.value] }
      .map { |key, codes| key if codes.many? }
      .compact
  end

  def duplicated_code_spaces
    return [] unless codes

    codes
      .select { |code| !code.code_space.allow_multiple_values }
      .group_by(&:code_space_id)
      .map { |code_space_id, codes| code_space_id if codes.many? }
      .compact
      .uniq
  end
end