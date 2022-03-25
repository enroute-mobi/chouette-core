module PointOfInterest
  class Base < ApplicationModel

    self.table_name = "point_of_interests"
    validates :name, presence: true
    validates :point_of_interest_category, presence: true

    belongs_to :shape_referential, required: true
    belongs_to :shape_provider, required: true

    belongs_to :point_of_interest_category, class_name: "PointOfInterest::Category", optional: false, inverse_of: :point_of_interests
    belongs_to :point_of_interest_hour, class_name: "PointOfInterest::Hour", optional: true, inverse_of: :point_of_interests

    has_many :codes, as: :resource, dependent: :delete_all
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
    validates_associated :codes

    def self.policy_class
      PointOfInterestPolicy
    end

    def self.model_name
      ActiveModel::Name.new self, nil, "PointOfInterest"
    end

  end
end
