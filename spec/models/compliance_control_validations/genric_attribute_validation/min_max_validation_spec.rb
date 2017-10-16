RSpec.describe GenericAttributeControl::MinMax do

  let( :factory ){ :generic_attribute_control_min_max }
  subject{ build factory }

  it_behaves_like 'has min_max_values'

end
