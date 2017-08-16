# From Chouette import what we need ™
Route     = Chouette::Route

RSpec.describe ObjectIdFactory, type: :model do

  context 'create unique objectids' do 

    it 'creates a new object id' do
      objectid = described_class.for(Route, prefix: 'hello:Route:one')
      expect( objectid ).to eq( "hello:Route:one_#{described_class.last.id}" )
    end

    it 'is clever enough to avoid conflicts' do
      route = create :route, objectid: 'hello:Route:one_1' 
      expect( described_class ).to receive(:create).and_return(described_class.new(id: 1))
      expect( described_class ).to receive(:create).and_return(described_class.new(id: 2))
      objectid = described_class.for(Route, prefix: 'hello:Route:one')
      expect( objectid ).to eq( "hello:Route:one_2" )
    end
    
  end
end
