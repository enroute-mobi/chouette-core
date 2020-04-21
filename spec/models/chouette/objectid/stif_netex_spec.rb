
describe Chouette::Objectid::StifNetex, :type => :model do
  subject { Chouette::Objectid::StifNetex.new(object_type: 'Route', local_id: '13') }
  it { should validate_presence_of :provider_id }
  it { should validate_presence_of :object_type }
  it { should validate_presence_of :local_id }
  it { should validate_presence_of :creation_id }
  it { is_expected.to be_valid }
end