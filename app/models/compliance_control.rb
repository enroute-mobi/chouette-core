class ComplianceControl < ActiveRecord::Base
  extend Enumerize
  belongs_to :compliance_control_set
  belongs_to :compliance_control_block

  enumerize :criticity, in: %i(info warning error), scope: true, default: :info

  validates :criticity, presence: true
  validates :name, presence: true
  validates :code, presence: true
  validates :origin_code, presence: true
  validates :compliance_control_set, presence: true

  class << self
    def default_criticity; :warning end
    def default_code; "" end

    def policy_class
      ComplianceControlPolicy
    end

    def inherited(child)
      child.instance_eval do
        def model_name
          ComplianceControl.model_name
        end
      end
      super
    end
  end

  before_validation(on: :create) do
   self.name ||= self.class.name
   self.code ||= self.class.default_code
   self.origin_code ||= self.class.default_code
  end

end

# Ensure STI subclasses are loaded
# http://guides.rubyonrails.org/autoloading_and_reloading_constants.html#autoloading-and-sti
require_dependency 'generic_attribute_control/min_max'
