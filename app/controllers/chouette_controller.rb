class ChouetteController < InheritedResources::Base
  include ApplicationHelper

  private

  def begin_of_association_chain
    current_organisation
  end
end
