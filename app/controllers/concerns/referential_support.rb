module ReferentialSupport
  extend ActiveSupport::Concern

  included do
    before_action :switch_referential
    alias_method :current_referential, :referential
    helper_method :current_referential
  end

  def switch_referential
    authorize referential, :browse?
    Apartment::Tenant.switch!(referential.slug)
  end

  def referential
    @referential ||= find_referential
  end

  def find_referential
    current_organisation.find_referential params[:referential_id]
  end

end
