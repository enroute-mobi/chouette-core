class ServiceFacilitySet < ActiveRecord::Base
  include CodeSupport
  extend Enumerize

  belongs_to :referential, required: true

  validates :name, presence: true

  delegate :workbench, to: :referential

  def candidate_categories
    Chouette::ServiceFacility.categories
  end

  def display_associated_services
    associated_services.map(&:human_name).join(', ')
  end

  def associated_services
    super.reject(&:blank?).map { |associated_service| Chouette::ServiceFacility.from(associated_service) }
  end
end