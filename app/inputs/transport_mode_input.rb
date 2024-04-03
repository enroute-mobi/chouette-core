# frozen_string_literal: true

class TransportModeInput < GroupedTomSelectInput
  def options
    super.merge(
      group_method: :self_and_sub_modes,
      group_label_method: :human_name,
      label_method: :human_name,
      value_method: :code
    )
  end
end
