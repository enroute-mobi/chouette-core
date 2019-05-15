RSpec.describe Chouette::Netex::Operator, type: :netex_resource do
  let(:resource){ create :company }
  let(:workgroup){ create :workgroup, line_referential: resource.line_referential }

  it_behaves_like 'it has default netex resource attributes'

  it_behaves_like 'it outputs custom fields'

  it_behaves_like 'it has children matching attributes', {
    'PublicCode' => :code,
    'CompanyNumber' => :registration_number,
    'Name' => :name,
    'ShortName' => :short_name,
    'ContactDetails > Email' => :default_contact_email,
    'ContactDetails > Phone' => :default_contact_phone,
    'ContactDetails > Url' => :default_contact_url
  }

  context 'without contact attributes' do
    before(:each) do
      resource.update default_contact_email: nil, default_contact_phone: nil, default_contact_url: nil
    end
    it_behaves_like 'it has no child', 'ContactDetails'
  end
end
