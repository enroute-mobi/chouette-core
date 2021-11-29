RSpec.describe Macro::CreateCode do
    it { is_expected.to validate_inclusion_of(:target_model).
                          in_array(%w(StopArea Line VehicleJourney)) }
    it { is_expected.to validate_presence_of(:source_attribute) }
    it { is_expected.to_not validate_presence_of(:source_pattern) }
    it { is_expected.to validate_presence_of(:target_code_space) }
    it { is_expected.to_not validate_presence_of(:target_pattern) }

    it "should be one of the available Macro" do
      expect(Macro.available).to include(described_class)
    end
end
