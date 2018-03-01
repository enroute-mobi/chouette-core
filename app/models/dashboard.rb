#
# The default Dashboard implementation can be customized in an initializer :
#
#   Rails.application.config.to_prepare do
#     Dashboard.default_class = Custom::Dashboard
#   end
#
class Dashboard
  include ActiveModel::Conversion

  @@default_class = self
  mattr_accessor :default_class

  def self.model_name
    ActiveModel::Name.new Dashboard, Dashboard, "Dashboard"
  end

  attr_reader :context
  def initialize(context)
    @context = context
  end

  def self.create(context)
    default_class.new context
  end

  def current_organisation
    context.send(:current_organisation)
  end

  def workbench
    @workbench ||= current_organisation.workbenches.default
  end

  def workgroup
    workbench.workgroup
  end

  def calendars
    workgroup.calendars.where('(organisation_id = ? OR shared = ?)', current_organisation.id, true)
  end
end
