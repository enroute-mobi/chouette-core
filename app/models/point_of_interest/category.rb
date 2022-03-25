module PointOfInterest
  class Category < ApplicationModel

    self.table_name = "point_of_interest_categories"
    validates :name, presence: true

    belongs_to :shape_referential, required: true
    belongs_to :shape_provider, required: true

    has_many :point_of_interests, -> { order(position: :asc) }, class_name: "PointOfInterest::Base", dependent: :delete_all, foreign_key: "point_of_interest_category_id", inverse_of: :point_of_interest
    has_many :codes, as: :resource, dependent: :delete_all
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
    validates_associated :codes

    before_validation :define_shape_referential, on: :create

    def self.policy_class
      PointOfInterestPolicy
    end

    private

    def define_shape_referential
      # TODO Improve performance ?
      self.shape_referential ||= shape_provider&.shape_referential
    end
  end
end
