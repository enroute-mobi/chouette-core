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
    associated_services.map{ |associated_service| Chouette::ServiceFacility.from(associated_service)&.human_name }.reject(&:blank?).join(', ')
  end
end