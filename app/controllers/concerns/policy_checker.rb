# frozen_string_literal: true

module PolicyChecker
  extend ActiveSupport::Concern

  include Policy::Authorization

  included do
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :authorize_resource, only: %i[edit update destroy]
    before_action :authorize_resource_class, only: %i[new create]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    helper_method :resource_policy, :parent_policy
  end

  protected

  def resource_policy
    @resource_policy ||= policy(resource)
  end

  def parent_policy
    @parent_policy ||= policy(parent_for_parent_policy)
  end

  def parent_for_parent_policy
    self.class.parents_symbols.any? ? parent : current_user
  end

  def authorize_resource
    authorize_policy(resource_policy, nil)
  end

  def authorize_resource_class
    authorize_policy(parent_policy, nil, resource_class)
  end
end
