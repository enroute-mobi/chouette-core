module Macro
  class CreateCode < Base
    option :target_model
    # Use enumerize directly
    enumerize :target_model, in: %w{StopArea Line VehicleJourney}

    option :source_attribute # TODO use ModelAttribute ?
    option :source_pattern
    option :target_code_space # TODO must be id or short_name of one of Workgroup CodeSpaces
    option :target_pattern

    # Use standard Rails validation methods
    validates :target_model, :source_attribute, :target_code_space, presence: true
  end
end
