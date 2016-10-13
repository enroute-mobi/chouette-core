require 'spec_helper'

describe 'reflex:sync' do
  context 'On first sync' do
    before(:each) do
      ['getOP', 'getOR'].each do |method|
        stub_request(:get, "#{Rails.application.config.reflex_api_url}/?format=xml&idRefa=0&method=#{method}").
        to_return(body: File.open("#{fixture_path}/reflex.zip"), status: 200)
      end

      stop_area_ref = create(:stop_area_referential, name: 'Reflex')
      create(:stop_area_referential_sync, stop_area_referential: stop_area_ref)
      Stif::ReflexSynchronization.synchronize
    end

    it 'should create stopArea on successfull request' do
      expect(Chouette::StopArea.count).to eq 6
      expect(Chouette::AccessPoint.count).to eq 2
    end

    it 'should convert StopPlaceEntrance to AccessPoint' do
      access = Chouette::AccessPoint.find_by(name: 'Montgeron Crosne - Rue Du Moulin De Senlis')
      expect(access.stop_area.name).to eq 'First stopPlace children'
    end

    it 'should save hierarchy' do
      stop_area = Chouette::StopArea.find_by(name: 'First stopPlace children')
      expect(stop_area.parent.name).to eq 'First stopPlace'
    end

    it 'should map xml data to StopArea attribute' do
      stop_area = Chouette::StopArea.find_by(objectid: 'FR:77153:LDA:69325:STIF')
      expect(stop_area.zip_code).to eq '77153'
      expect(stop_area.area_type).to eq 'StopPlace'
    end

    context 'On next sync' do
      before(:each) do
        ['getOP', 'getOR'].each do |method|
          stub_request(:get, "#{Rails.application.config.reflex_api_url}/?format=xml&idRefa=0&method=#{method}").
          to_return(body: File.open("#{fixture_path}/reflex_updated.zip"), status: 200)
        end
        Stif::ReflexSynchronization.synchronize
      end

      it 'should not create duplicate stop_area' do
        expect(Chouette::StopArea.count).to eq 6
        expect(Chouette::AccessPoint.count).to eq 2
      end

      it 'should flag deleted_at for missing element from last sync' do
        stop_area = Chouette::StopArea.find_by(name: 'Second StopPlace')
        expect(stop_area.deleted_at).to be_within(1.minute).of(Time.now)
      end

      it 'should update existing stop_area' do
        expect(Chouette::StopArea.where(name: 'First stopPlace edited')).to exist
        expect(Chouette::StopArea.where(name: 'First stopPlace children edited')).to exist
      end
    end
  end
end
