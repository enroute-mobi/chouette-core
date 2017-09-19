EnumBox = Support::DataModifier::EnumBox

RSpec.describe Chouette::RoutingConstraintZone, type: :checksum do
  before do
    2.times{ create :route }
  end
  let( :factory ){ :routing_constraint_zone }
  let( :base_atts ){{route_id: EnumBox.new(Chouette::Route.first.id, Chouette::Route.last.id)}} 

  let( :same_checksum_atts ){ base_atts.merge(name: random_string) }

  it_behaves_like 'checksummed model'
end
