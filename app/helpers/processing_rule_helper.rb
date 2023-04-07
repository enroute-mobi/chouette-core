# frozen_string_literal: true

module ProcessingRuleHelper
  def processing_rules_names(processing_rules)
    if processing_rules.count.zero?
      '-'
    else
      "#{processing_rules.count} #{ProcessingRule::Base.model_name.human(count: processing_rules.count)}"
    end
  end
end
