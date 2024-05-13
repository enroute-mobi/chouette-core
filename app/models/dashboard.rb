#
# The default Dashboard implementation can be customized in an initializer :
#
#   Rails.application.config.to_prepare do
#     Dashboard.default_class = Custom::Dashboard
#   end
#
class Dashboard
  extend ActiveModel::Translation
  include ActiveModel::Conversion

  @@default_class = self
  mattr_accessor :default_class

  attr_reader :context
  def initialize(context)
    @context = context
  end

  delegate :current_user, to: :context

  def self.create(context)
    default_class.new context
  end

  def current_organisation
    context.send(:current_organisation)
  end

end
