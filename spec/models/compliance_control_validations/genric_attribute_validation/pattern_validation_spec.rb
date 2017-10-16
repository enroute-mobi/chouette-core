RSpec.describe GenericAttributeControl::Pattern do

  let( :factory ){ :generic_attribute_control_pattern }
  subject{ build factory }

  context "is valid" do
    it 'if the pattern contains a basic regex' do
      subject.pattern = 'hel+o?'
      expect_it.to be_valid
    end
  end

  context "is invalid" do
    it 'if no pattern has been provided' do
      expect_it.not_to be_valid
    end
    it 'if the pattern is empty' do
      subject.pattern = '  '
      expect_it.not_to be_valid
    end

  end
end
