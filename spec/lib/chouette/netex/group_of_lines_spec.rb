RSpec.describe Chouette::Netex::GroupOfLines, type: :netex_resource do
  let(:resource){ create :network, comment: 'Lorem Ipsum' }

  it_behaves_like 'it has default netex resource attributes'
  it_behaves_like 'it has children matching attributes', {
    'Name' => :name,
    'Description' => :comment,
    'PrivateCode' => :registration_number
  }
end
