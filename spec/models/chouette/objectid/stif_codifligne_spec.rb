
describe Chouette::Objectid::StifCodifligne, :type => :model do
  subject { Chouette::Objectid::StifCodifligne.new(object_type: 'Line', local_id: 'C02008', sync_id: 'CODIFLIGNE', provider_id: 'STIF') }
  it { should validate_presence_of :provider_id }
  it { should validate_presence_of :object_type }
  it { should validate_presence_of :local_id }
  it { is_expected.to be_valid }

  it 'should accept different formats' do
    [
      'STIF:CODIFLIGNE:Line:C00001',
      'FR1:Line:C01128:',
      'FR1:Line:C01128:LOC'
    ].each do |string|
      objectid = Chouette::ObjectidFormatter::StifCodifligne.new.get_objectid(string)
      expect(objectid).to be_valid
      expect(objectid.to_s).to eq string
    end
  end

  it 'should deny wrong formats' do
    [
      'STIF:CODIFLIGNE::C00001',
      'FR1::C01128:LOC'
    ].each do |string|
      objectid = Chouette::ObjectidFormatter::StifCodifligne.new.get_objectid(string)
      expect(objectid).to_not be_valid
    end
  end
end
