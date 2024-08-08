# frozen_string_literal: true

module PointOfInterest
  class Category < ApplicationModel
    include ShapeReferentialSupport
    include CodeSupport

    self.table_name = "point_of_interest_categories"
    validates :name, presence: true

    belongs_to :parent, class_name: "PointOfInterest::Category", required: false

    has_many :point_of_interests, class_name: "PointOfInterest::Base", foreign_key: "point_of_interest_category_id", inverse_of: :point_of_interest_category
    has_many :point_of_interest_categories, class_name: "PointOfInterest::Category", foreign_key: "parent_id"

    def used?
      point_of_interests.exists? || point_of_interest_categories.exists?
    end
  end
end
