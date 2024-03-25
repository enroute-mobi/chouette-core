class AbstractCode < ActiveRecord::Base
  self.abstract_class = true

  acts_as_copy_target

  belongs_to :code_space, required: true
  belongs_to :resource, polymorphic: true, required: true

  validates :value, presence: true

  scope :by_resource_type, ->(resource_class) { where resource_type: resource_class.to_s }

  def self.merge(existing_codes, new_codes)
    return if new_codes.blank?

    new_codes.each do |new_code|
      next if existing_codes.any? do |code|
        code.code_space_id == new_code.code_space_id && code.value == new_code.value
      end

      existing_codes << new_code
    end
  end

  def self.unpersisted(codes, code_spaces: {})
    codes.map do |code|
      attributes = code.attributes.extract!('value', 'code_space_id')

      code.class.new(attributes).tap do |new_code|
        new_code.code_space = code_spaces[new_code.code_space_id]
      end
    end
  end
end
