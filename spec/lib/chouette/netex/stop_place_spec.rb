RSpec.describe Chouette::Netex::StopPlace do
  let(:stop_area){ create :stop_area, longitude: 12, latitude: 45.12, localized_names: {gb: 'Foo'} }

  let(:subject){ Chouette::Netex::StopPlace.new(stop_area) }
  let(:result) do
     Nokogiri::XML::Builder.new do |builder|
       subject.to_xml(builder)
     end
   end
   let(:node){ result.doc.css('StopPlace').first }

  it 'should have correct attributes' do
    Timecop.freeze '2000-01-01 12:00 UTC' do
      expect(node['version']).to eq 'any'
      expect(node['id']).to eq stop_area.objectid
      expect(node['created']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['changed']).to eq '2000-01-01T12:00:00.0Z'
      expect(node['status']).to eq 'active'
      expect(node.css('Centroid Location Longitude').last.text).to eq stop_area.longitude.to_s
      expect(node.css('Centroid Location Latitude').last.text).to eq stop_area.latitude.to_s
    end
  end

  context 'with a desactivated stop_area' do
    it 'should have correct attributes' do
      stop_area.update deleted_at: Time.now
      expect(node['status']).to eq 'inactive'
    end
  end

  {
    'Name' => 'name',
    'Description' => 'comment',
    'Url' => 'url',
    'PrivateCode' => 'registration_number'
  }.each do |tag, attribute|
    it "should have a #{tag} child matching #{attribute} attribute" do
      expect(node.css(tag).size).to eq 1
      expect(node.css(tag).first.text.presence).to eq stop_area.send(attribute)
    end
  end

  context 'with ZDEP children' do
    it 'should add quays' do
      stop_area.update area_type: :gdl, kind: :commercial
      create :stop_area, parent: stop_area, area_type: :zdep, kind: :commercial

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
        stop_area.update area_type: type, kind: :commercial
        expect(node.css('placeTypes TypeOfPlaceRef').last['ref']).to eq out
      end
    end

    %i[deposit border service_area relief other].each do |k|
      it 'should match the stop area type' do
        stop_area.update area_type: k, kind: :non_commercial
        expect(node.css('placeTypes TypeOfPlaceRef').last['ref']).to eq k.to_s
        if k == :border
          expect(node.css('PublicUse').last.text).to eq 'staffOnly'
        else
          expect(node.css('PublicUse').last.text).to be_empty
        end
      end
    end

    it 'should fill the PostalAddress' do
      stop_area.update country_code: :fr
      expect(node.css('PostalAddress CountryRef').last.text).to eq 'FR'
      expect(node.css('PostalAddress Town').last.text).to eq stop_area.city_name
      expect(node.css('PostalAddress AddressLine1').last.text).to eq stop_area.street_name
      expect(node.css('PostalAddress PostCode').last.text).to eq stop_area.zip_code
    end

    it 'should fill the keyList' do
      stop_area.update country_code: :fr, waiting_time: 10, time_zone: "Europe/Paris"

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
