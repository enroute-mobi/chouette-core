# frozen_string_literal: true

module WithinWorkgroup
  extend ActiveSupport::Concern

  included do
    around_action :set_current_workgroup
  end

  def set_current_workgroup(&block)
    # Ensure that InheritedResources has defined parents (workbench, etc)
    association_chain

    CustomFieldsSupport.within_workgroup current_workgroup, &block
  end
end
