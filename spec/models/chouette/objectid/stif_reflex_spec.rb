require 'spec_helper'

describe Chouette::Objectid::StifReflex, :type => :model do
  subject { Chouette::Objectid::StifReflex.new(country_code: 'FR', object_type: 'ZDL', local_id: '50015386', provider_id: 'STIF') }
  it { should validate_presence_of :provider_id }
  it { should validate_presence_of :object_type }
  it { should validate_presence_of :local_id }
  it { is_expected.to be_valid }

  it 'should accept different formats' do
    [
      'FR::Quay:50123420:FR1',
      'FR1:PostalAddress:50123420:',
    ].each do |string|
      objectid = Chouette::ObjectidFormatter::StifReflex.new.get_objectid(string)
      expect(objectid).to be_valid
      expect(objectid.to_s).to eq string
    end
  end

  it 'should deny wrong formats' do
    [
      'FR::Quay:50123420:FR1:',
      'FR:Quay:50123420:FR1',
      'FR::PostalAddress:1234:',
      'FR::Quay:1234',
      'FR:PostalAddress:1234'
    ].each do |string|
      objectid = Chouette::ObjectidFormatter::StifReflex.new.get_objectid(string)
      expect(objectid).to_not be_valid
    end
  end
end