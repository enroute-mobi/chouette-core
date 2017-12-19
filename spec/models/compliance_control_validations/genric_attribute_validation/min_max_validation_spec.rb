RSpec.describe GenericAttributeControl::MinMax do

  let( :factory ){ :generic_attribute_control_min_max }
  subject{ build factory }

  it_behaves_like 'has min_max_values'

  context "numerical validation" do
    context "valid" do
      it "on assignment" do
        subject.minimum = 42
        expect_it.to be_valid
      end
      it "on FactoryGirl build" do
        instance =  build factory, minimum: "41" 
        expect(instance).to be_valid
      end
      
      it "on new" do
        instance = described_class.new(target: "target", minimum: "40")
        expect(instance).not_to be_valid
      end

      it "on update" do
        subject.update minimum: '39'
        expect(subject).to be_valid
      end

      it 'on assign_attributes' do
        subject.assign_attributes minimum: 38
        expect(subject).to be_valid
      end
    end

    context "invalid" do
      it "on assignment" do
        subject.minimum = "42s"
        expect_it.not_to be_valid
      end

      it "on FactoryGirl build" do
        instance =  build factory, minimum: "41s" 
        expect(instance).not_to be_valid
      end
      
      it "on new" do
        instance = described_class.new(target: "target", minimum: "40s")
        expect(instance).not_to be_valid
      end

      it "on update" do
        subject.update minimum: '39s'
        expect(subject).not_to be_valid
      end

      it 'on assign_attributes' do
        subject.assign_attributes minimum: 'x38'
        expect(subject).not_to be_valid
      end
    end
  end
end
