# frozen_string_literal: true

class SequenceDecorator < Af83::Decorator
  decorates Sequence

  set_scope { context[:workbench] }

  create_action_link

  with_instance_decorator(&:crud)

  define_instance_method :alpine_state do |is_export|
    initial_state = { sequence_type: object.sequence_type, static_list: object.static_list }

    object.static_list.reduce(initial_state) do |result, (k, v)|
      result[k.camelcase(:lower)] = v

      result
    end.to_json
  end
end
