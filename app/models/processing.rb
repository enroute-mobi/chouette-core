# frozen_string_literal: true

class Processing < ApplicationModel
  extend Enumerize
  
  belongs_to :workgroup, optional: true
  belongs_to :workbench, optional: true

  # Import, Merge, Aggregate
  belongs_to :operation, polymorphic: true, optional: false

  # Associated Macro::List::Run / Control::List:Run
  belongs_to :processed, polymorphic: true, optional: false

  # Associated ProcessingRule::Workbench / ProcessingRule::Workgroup
  belongs_to :processing_rule, polymorphic: true, optional: false
  
  enumerize :step, in: %i{before after}
  
  
  def perform
    processed.perform
    processed.user_status.successful?
  end
end