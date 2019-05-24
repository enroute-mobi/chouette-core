require 'stif/reflex_synchronization'

RSpec.describe Stif::ReflexSynchronization do
  let(:api_url) { "https://pprod.reflex.stif.info/ws/rest/V2/getData?method=getAll" }
  let!(:stop_area_referential) { create :stop_area_referential, name: 'Reflex' }

  before(:each) do
    stub_request(:get, api_url).to_return(body: File.open("#{fixture_path}/reflex.xml"), status: 200)
    Stif::ReflexSynchronization.synchronize
  end

  it 'should retreive the correct number of data' do
    expect(stop_area_referential.stop_areas.count).to eq 4
    expect(stop_area_referential.stop_area_providers.count).to eq 1
  end

  it 'should have correct area_type of stop areas' do
    stop = stop_area_referential.stop_areas.find_by(name: 'Gutenberg - Lycée Boulloche')
    expect(stop.area_type).to eq 'zdlp'
    expect(stop.is_referent).to be_truthy

    stop = stop_area_referential.stop_areas.find_by(name: 'GUTENBERG - Lycée Boulloche')
    expect(stop.area_type).to eq 'lda'

    stop = stop_area_referential.stop_areas.find_by(name: 'Gutenberg')
    expect(stop.area_type).to eq 'zdep'
    expect(stop.is_referent).to be_truthy

    stop = stop_area_referential.stop_areas.find_by(name: 'GUTENBERG')
    expect(stop.area_type).to eq 'zdep'
    expect(stop.is_referent).to be_falsey
  end

  it 'should correctly handle parents' do
    stop = stop_area_referential.stop_areas.find_by(name: 'Gutenberg - Lycée Boulloche')
    parent = stop_area_referential.stop_areas.find_by(name: 'GUTENBERG - Lycée Boulloche')
    expect(stop.parent).to eq(parent)

    stop = stop_area_referential.stop_areas.find_by(name: 'Gutenberg')
    parent = stop_area_referential.stop_areas.find_by(name: 'Gutenberg - Lycée Boulloche')
    expect(stop.parent).to eq(parent)
  end
end
