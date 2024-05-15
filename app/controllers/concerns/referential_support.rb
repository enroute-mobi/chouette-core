# frozen_string_literal: true

module ReferentialSupport
  extend ActiveSupport::Concern

  included do
    before_action :switch_referential
    helper_method :current_referential
  end

  def switch_referential
    authorize referential, :browse?
    Apartment::Tenant.switch!(referential.slug)
  end

  def referential
    @referential ||= find_referential
  end

  def current_referential
    referential
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def find_referential
    workbench.find_referential!(params[:referential_id])
  end
end
