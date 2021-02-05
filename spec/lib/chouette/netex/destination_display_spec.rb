RSpec.describe Chouette::Netex::DestinationDisplay, type: :netex_resource do
  let(:resource){ create :journey_pattern, name: "Nom", published_name: "Nom publié" }

  it_behaves_like 'it has default netex resource attributes'

  it_behaves_like 'it has children matching attributes', { 'FrontText' => :published_name }
end
