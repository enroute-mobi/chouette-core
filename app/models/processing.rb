# frozen_string_literal: true

class Processing < ApplicationModel
  extend Enumerize

  belongs_to :workgroup, optional: true
  belongs_to :workbench, optional: true

  # Import, Merge, Aggregate. Optional: a scheduled ProcessingRule (see ProcessingRule::Scheduling)
  # performs without any triggering operation.
  belongs_to :operation, polymorphic: true, optional: true

  # Associated Macro::List::Run / Control::List:Run
  belongs_to :processed, polymorphic: true, dependent: :destroy # CHOUETTE-3247 optional: false

  # Associated ProcessingRule::Workbench / ProcessingRule::Workgroup
  belongs_to :processing_rule, class_name: 'ProcessingRule::Base' # CHOUETTE-3247 optional: false

  enumerize :step, in: %i[before after scheduling]

  def perform
    processed.perform
    processed.user_status.successful? || processed.user_status.warning?
  end
end
