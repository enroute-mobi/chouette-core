# frozen_string_literal: true

# Used to change the base object_name to create form template
class NewScopeFormBuilder < SimpleForm::FormBuilder
  def initialize(*arguments)
    super

    # macro_list[macros_attributes][new_child] => new_scope[macros_attributes][new_child]
    @object_name = @object_name.gsub(/^[a-z_]+\[/, 'new_scope[')
  end
end
