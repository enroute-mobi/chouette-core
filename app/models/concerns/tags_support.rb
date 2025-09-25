# frozen_string_literal: true

module TagsSupport
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, class_name: 'Tagging', dependent: :destroy
    has_many :tags, through: :taggings

    accepts_nested_attributes_for :taggings, allow_destroy: true
  end

  class_methods do
    def has_tags(name)
      has_many association_name_taggings(name),
               -> { where(for_association: name) },
               as: :taggable,
               class_name: 'Tagging',
               dependent: :destroy

      has_many name, through: association_name_taggings(name), source: :tag

      accepts_nested_attributes_for association_name_taggings(name), allow_destroy: true
    end

    private

    def association_name_taggings(name)
      [name, 'taggings'].compact.join('_').to_sym
    end
  end
end
