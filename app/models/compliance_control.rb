class ComplianceControl < ApplicationModel
  include ComplianceItemSupport

  class << self

    def criticities
      %i(warning error)
    end

    def default_code
      ""
    end

    def policy_class
      ComplianceControlPolicy
    end

    def block_class
      self.parent.to_s.sub('Control', '').underscore
    end

    def iev_enabled_check
      true
    end

    def available_for_organisation? organisation
      out = @required_features.present? ? ((organisation.features.map(&:to_sym) & @required_features.map(&:to_sym)).size == @required_features.map(&:to_sym).size) : true
      out && (@constraints || []).all?{|test| !!test.call(organisation) }
    end

    def required_features *features
      @required_features ||= []
      @required_features += features
    end

    def only_if test
      @constraints ||= []
      @constraints << test
    end

    def only_with_custom_field klass, field_code
      only_if ->(organisation) { organisation.workgroups.any?{|workgroup| klass.custom_fields(workgroup).where(code: field_code).exists? }}
    end

    def object_type
      _, type, _ = self.default_code.split('-')

      type.underscore
    end

    def inherited(child)
      child.instance_eval do
        def model_name
          ComplianceControl.model_name
        end
      end
      super
    end

    def predicate
      I18n.t("compliance_controls.#{self.name.underscore}.description")
    end

    def prerequisite
      I18n.t("compliance_controls.#{self.name.underscore}.prerequisite")
    end
  end

  extend Enumerize
  belongs_to :compliance_control_set
  belongs_to :compliance_control_block
  has_one :organisation, through: :compliance_control_set

  enumerize :criticity, in: criticities, scope: true, default: :warning

  validates :criticity, presence: true
  validates :name, presence: true
  validates :code, presence: true, uniqueness: { scope: :compliance_control_set }
  validates :origin_code, presence: true
  validates :compliance_control_set, presence: true

  validate def coherent_control_set
    return true if compliance_control_block_id.nil?
    ids = [compliance_control_block.compliance_control_set_id, compliance_control_set_id]
    return true if ids.first == ids.last
    names = ids.map{|id| ComplianceControlSet.find(id).name}
    errors.add(:coherent_control_set,
               I18n.t('compliance_controls.errors.incoherent_control_sets',
                      indirect_set_name: names.first,
                      direct_set_name: names.last))
  end

  def initialize(attributes = {})
    super
    self.name ||= I18n.t("activerecord.models.#{self.class.name.underscore}.one")
    self.code ||= self.class.default_code
    self.origin_code ||= self.class.default_code
  end

  def predicate
    self.class.predicate
  end

  def prerequisite
    self.class.prerequisite
  end

end

# https://guides.rubyonrails.org/autoloading_and_reloading_constants_classic_mode.html#require-dependency-and-initializers
%w(
  company
  custom_field
  dummy
  generic_attribute
  journey_pattern
  line
  route
  routing_constraint_zone
  stop_area
  vehicle_journey
).each do |n|
  dir = Dir[File.join(__dir__, "#{n}_control", '*.rb')]
  dir.each { |f| require_dependency f } 
end
