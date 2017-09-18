RSpec.describe Chouette::Footnote do

  let( :factory ){ :footnote }
  let( :base_atts ){ {code: 'alpha', label: 'a'} }

  let( :line ){ create :line }
  let( :same_checksum_atts ){ {code: 'alpha', label: 'a', line: line} }

  it_behaves_like 'checksummed model'
end
