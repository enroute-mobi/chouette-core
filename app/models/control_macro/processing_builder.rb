# frozen_string_literal: true

module ControlMacro
  class ProcessingBuilder < ::ProcessingRule::ProcessingBuilder
    delegate :processable, to: :processing_rule

    protected

    def processed_attributes
      {
        name: processable.name,
        creator: 'Webservice',
        referential: referential,
        workbench: operation_workbench
      }
    end
  end
end
