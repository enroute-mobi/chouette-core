module PointOfInterest
  class Category < ApplicationModel
    include CodeSupport

    self.table_name = "point_of_interest_categories"
    validates :name, presence: true

    belongs_to :shape_referential, required: true
    belongs_to :shape_provider, required: true
    belongs_to :parent, class_name: "PointOfInterest::Category", required: false

    has_many :point_of_interests, class_name: "PointOfInterest::Base", foreign_key: "point_of_interest_category_id", inverse_of: :point_of_interest_category
    has_many :point_of_interest_categories, class_name: "PointOfInterest::Category", foreign_key: "parent_id"

    before_validation :define_shape_referential, on: :create

    def self.policy_class
      PointOfInterestCategoryPolicy
    end

    def used?
      point_of_interests.exists? || point_of_interest_categories.exists?
    end

    private

    def define_shape_referential
      self.shape_referential ||= shape_provider&.shape_referential
    end
  end
end
