# coding: utf-8
require 'stif/reflex_synchronization'

RSpec.describe Stif::ReflexSynchronization do
  let(:api_url) { "https://pprod.reflex.stif.info/ws/rest/V2/getData?method=getAll" }
  let!(:stop_area_referential) { create :stop_area_referential, name: 'Reflex' }
  let!(:stop_area_provider) { create :stop_area_provider, objectid: "FR1:OrganisationalUnit:8:", stop_area_referential_id: stop_area_referential.id}
  let!(:default_referent_stop_area_provider) { create :stop_area_provider, objectid: "FR1-ARRET_AUTO", stop_area_referential_id: stop_area_referential.id}

  # let(:context) do
  #   Chouette.create do
  #     stop_area_provider
  #   end
  # end
  #
  # let(:target) { context.stop_area_referential }
  # let(:stop_area_provider) { context.stop_area_provider }

  describe "with reflex file not referencing referent stop areas" do
    before(:each) do
      stub_request(:get, api_url).to_return(body: File.open("#{fixture_path}/reflex_without_referents.xml"), status: 200)
    end

    describe "with every stop area referencing an already existing provider" do

      it 'should not create any stop area referential' do
        expect{Stif::ReflexSynchronization.synchronize}.not_to(change { stop_area_referential.stop_area_providers.count })
      end

      it 'should create the correct number of stop areas' do
        expect{Stif::ReflexSynchronization.synchronize}.to change {stop_area_referential.stop_areas.count }.by(4)
        expect(stop_area_referential.stop_areas.count).to eq 4
        expect(stop_area_provider.stop_areas.count).to eq 4
      end

    end

    describe "with some stop areas not referencing an already existing provider" do
      let!(:stop_area_provider) { create :stop_area_provider, objectid: "FR1:TestProvider:1:", stop_area_referential_id: stop_area_referential.id}

      it 'should not create any stop area referential' do
        expect{Stif::ReflexSynchronization.synchronize}.not_to change { stop_area_referential.stop_area_providers.count }
      end

      it 'should not create the associated stop areas' do
        expect{Stif::ReflexSynchronization.synchronize}.not_to change {stop_area_referential.stop_areas.count }
        expect(stop_area_referential.stop_areas.count).to eq 0
        expect(stop_area_provider.stop_areas.count).to eq 0
      end

    end

  end


  describe "with reflex file referencing referent stop areas" do
    before(:each) do
      stub_request(:get, api_url).to_return(body: File.open("#{fixture_path}/reflex.xml"), status: 200)
      Stif::ReflexSynchronization.synchronize
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
end
