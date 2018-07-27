class ChouetteController < InheritedResources::Base
  include ApplicationHelper

  before_action :load_referential

  protected

  def load_referential
    @referential ||= Referential.find(params[:referential_id]) if params[:referential_id]
  end

  def begin_of_association_chain
    current_organisation
  end
end
