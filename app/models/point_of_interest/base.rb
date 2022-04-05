module PointOfInterest
  class Base < ApplicationModel

    self.table_name = "point_of_interests"

    belongs_to :shape_referential, required: true
    belongs_to :shape_provider, required: true

    belongs_to :point_of_interest_category, class_name: "PointOfInterest::Category", optional: false, inverse_of: :point_of_interests, required: true
    belongs_to :point_of_interest_hour, class_name: "PointOfInterest::Hour", optional: true, inverse_of: :point_of_interests

    has_many :codes, as: :resource, dependent: :delete_all
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank

    validates_associated :codes
    validates :name, :point_of_interest_category_id, presence: true

    before_validation :define_shape_referential, on: :create
    before_validation :position_from_input
    def position_from_input
      PositionInput.new(@position_input).change_position(self)
    end

    attr_writer :position_input

    def self.policy_class
      PointOfInterestPolicy
    end

    def self.model_name
      ActiveModel::Name.new self, nil, "PointOfInterest"
    end

    def position_input
      @position_input || ("#{position.y} #{position.x}" if position)
    end

    def longitude
      position&.x
    end
    def latitude
      position&.y
    end

    private

    def define_shape_referential
      self.shape_referential ||= shape_provider&.shape_referential
    end

  end
end
