# frozen_string_literal: true

class ServiceFacilitySetInput < GroupedTomSelectInput
  def options
    super.merge(
      group_method: :self_and_sub_categories,
      group_label_method: :human_name,
      label_method: :human_name,
      value_method: :code
    )
  end
end
