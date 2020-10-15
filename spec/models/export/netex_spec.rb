describe Export::Netex, type: :model do
  let( :boiv_iev_uri ){ URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/exporter/new?id=#{subject.id}") }

  before do
    allow(Thread).to receive(:new).and_yield
  end

  context 'options' do
    it 'should validate the options' do
      e = create(:netex_export)
      expect(e).to be_valid

      e.export_type = nil
      expect(e).to_not be_valid

      e.export_type = "full"
      e.duration = nil
      expect(e).to_not be_valid
      e.duration = 60
      expect(e).to be_valid
      e.duration = 0
      expect(e).to_not be_valid
      e.duration = 61
      expect(e).to_not be_valid

      e.export_type = "line"
      e.line_code = 42

      e.duration = nil
      expect(e).to_not be_valid
      e.duration = 365
      expect(e).to be_valid
      e.duration = 0
      expect(e).to_not be_valid
      e.duration = 366
      expect(e).to_not be_valid
    end
  end

  context 'with referential' do
    it 'will trigger the Java API' do
      expect_any_instance_of(Export::Netex).to receive(:threaded_call_boiv_iev)
      create( :netex_export, id: random_int )
    end
  end
end
