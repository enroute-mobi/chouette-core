RSpec.describe Chouette::Netex::Line, type: :netex_resource do
  let(:resource){ create :line, transport_submode: :demandAndResponseBus }

  it_behaves_like 'it has default netex resource attributes', { status: 'active' }

  it_behaves_like 'it has children matching attributes', {
    'Name' => 'published_name',
    'Url' => 'url',
    'PublicCode' => 'number',
    'PrivateCode' => 'registration_number',
    'TransportMode' => 'transport_mode',
    'TransportSubmode' => 'transport_submode',
  }

  it_behaves_like 'it has one child with value', 'OperatorRef', ->{ resource.company.objectid }
  it_behaves_like 'it has one child with value', 'RepresentedByGroupRef', ->{ resource.network.objectid }
end
