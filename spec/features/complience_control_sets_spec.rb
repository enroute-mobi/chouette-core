RSpec.describe "ComplianceControlSets", type: :feature do

  login_user

  let( :control_set ){ create :compliance_control_set }
  let( :min_max_class ){ GenericAttributeControl::MinMax }
  let( :pattern_class ){ GenericAttributeControl::Pattern }

  let( :common_atts ){{
    compliance_control_set: control_set,
  }}


  let(:blox){
    3.times.map{ | _ | create :compliance_control_block, compliance_control_set: control_set }
  }

  before do
    blox.each do | block |
      create( :generic_attribute_control_min_max, code: random_string, compliance_control_block: block, **common_atts )
      create( :generic_attribute_control_pattern, code: random_string, compliance_control_block: block, **common_atts )
    end
  end

  describe 'show' do
    it 'check setup' do
      each_kind_count = 3
      expect( min_max_class.count ).to  eq(each_kind_count)
      expect( pattern_class.count ).to  eq(each_kind_count)
      query = ComplianceControl.group(:compliance_control_block)
      require 'pry'; binding.pry
    end

  end

end
