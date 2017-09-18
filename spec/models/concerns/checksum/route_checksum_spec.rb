RSpec.describe Chouette::Route, type: :checksum do
  let( :factory ){ :route }

  let( :base_atts ){{
    name: 'sixty six',
    published_name: 'ninty nine',
    wayback: make_enum(:inbound, :outbound)
  }}

  let( :same_checksum_atts ){ base_atts.merge( object_version: base_atts.fetch(:object_version, 0).succ )  }
  it_behaves_like 'checksummed model'

end
