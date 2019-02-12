RSpec.describe Chouette::Netex::StopPlace, type: :netex_resource do
  let(:collection) { Chouette::StopArea.all }
  let(:resource){ create :stop_area, longitude: 12, latitude: 45.12, localized_names: {gb: 'Foo'} }

  it_behaves_like 'it has default netex resource attributes', { status: 'active' }
  it_behaves_like 'it has one child with value', 'Centroid Location Longitude', ->{ resource.longitude.to_s }
  it_behaves_like 'it has one child with value', 'Centroid Location Latitude', ->{ resource.latitude.to_s }

  context 'with a desactivated stop_area' do
    before(:each) do
      Timecop.freeze '2000-01-01 12:00 UTC' do
       resource.update deleted_at: Time.now
     end
   end

    it_behaves_like 'it has default netex resource attributes', { status: 'inactive' }
  end

  it_behaves_like 'it has children matching attributes', {
    '> Name' => 'name',
    'Description' => 'comment',
    'Url' => 'url',
    'PrivateCode' => 'registration_number'
  }

  context 'with ZDEP children' do
    it 'should add quays' do
      resource.update area_type: :gdl, kind: :commercial
      create :stop_area, parent: resource, area_type: :zdep, kind: :commercial
      expect(node.css('Quay').count).to eq 1
    end
  end

  context 'the typeOfPlace' do
    {
      gdl: 'groupOfStopPlaces',
      lda: 'generalStopPlace',
      zdlp: 'monomodalStopPlace',
      zdep: 'quay'
    }.each do |type, out|
      it 'should match the stop area type' do
        resource.update area_type: type, kind: :commercial
        expect(node.css('placeTypes TypeOfPlaceRef').last['ref']).to eq out
      end
    end

    %i[deposit border service_area relief other].each do |k|
      it 'should match the stop area type' do
        resource.update area_type: k, kind: :non_commercial
        expect(node.css('placeTypes TypeOfPlaceRef').last['ref']).to eq k.to_s
        if k == :border
          expect(node.css('PublicUse').last.text).to eq 'staffOnly'
        else
          expect(node.css('PublicUse').last.text).to be_empty
        end
      end
    end

    it 'should fill the PostalAddress' do
      resource.update country_code: :fr
      expect(node.css('PostalAddress CountryRef').last.text).to eq 'FR'
      expect(node.css('PostalAddress Town').last.text).to eq resource.city_name
      expect(node.css('PostalAddress AddressLine1').last.text).to eq resource.street_name
      expect(node.css('PostalAddress PostCode').last.text).to eq resource.zip_code
    end

    it 'should fill the keyList' do
      resource.update country_code: :fr, waiting_time: 10, time_zone: "Europe/Paris"

      node.css('keyList KeyValue').each do |key_value|
        if key_value.css('Key').last.text == 'WaitingTime'
          expect(key_value.css('Value').last.text).to eq '10'
        elsif key_value.css('Key').last.text == 'TimeZone'
          expect(key_value.css('Value').last.text).to eq 'Europe/Paris'
        elsif key_value.css('Key').last.text == 'TimeZoneOffset'
          expect(key_value.css('Value').last.text).to eq '1'
        end
      end
    end
  end
end
