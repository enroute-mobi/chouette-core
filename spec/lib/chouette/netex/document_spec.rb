RSpec.describe Chouette::Netex::Document do

  let(:subject){ Chouette::Netex::Document.new(referential) }

  it 'should insert all entities' do
    expect(subject).to receive :netex_operators
    expect(subject).to receive :netex_stop_places
    expect(subject).to receive :netex_lines
    expect(subject).to receive :netex_groups_of_lines

    subject.build
  end
end
