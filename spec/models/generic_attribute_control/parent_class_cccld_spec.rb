RSpec.describe ComplianceControl do
  context 'class attributes' do 
    it 'are correctly set' do
      expect( described_class ).to respond_to(:default_code)
    end
  end
end
