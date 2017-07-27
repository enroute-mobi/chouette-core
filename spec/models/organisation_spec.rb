describe Organisation, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:code) }

  it 'should have a valid factory' do
    expect(FactoryGirl.build(:organisation)).to be_valid
  end

  it "create a rule_parameter_set" do
    organisation = create(:organisation)
    expect(organisation.rule_parameter_sets.size).to eq(1)
  end

  describe "Portail sync" do
    let(:conf) { Rails.application.config.stif_portail_api }
    before :each do
      stub_request(:get, "#{conf[:url]}/api/v1/organizations").
      with(stub_headers(authorization_token: conf[:key])).
      to_return(body: File.open(File.join(Rails.root, 'spec', 'fixtures', 'organizations.json')), status: 200)
    end

    it 'should retrieve data from portail api' do
      expect(Organisation.portail_api_request).to be_truthy
      expect(WebMock).to have_requested(:get, "#{conf[:url]}/api/v1/organizations").
        with(headers: { 'Authorization' => "Token token=\"#{conf[:key]}\"" })
    end

    it 'should create new organisations' do
      expect{Organisation.portail_sync}.to change{ Organisation.count }.by(5)
      expect(Organisation.all.map(&:name)).to include 'ALBATRANS', 'OPTILE', 'SNCF', 'STIF'
    end

    it 'should retrieve functional scope' do
      Organisation.portail_sync
      org = Organisation.find_by(code: 'RATP')
      expect(org.sso_attributes['functional_scope']).to eq "[\"STIF:CODIFLIGNE:Line:C00840\", \"STIF:CODIFLIGNE:Line:C00086\"]"
    end

    it 'should update existing organisations' do
      create :organisation, name: 'dummy_name', code:'RATP', updated_at: 10.days.ago, sso_attributes: {functional_scope: "[\"STIF:CODIFLIGNE:Line:C00840\"]"}
      Organisation.portail_sync
      org = Organisation.find_by(code: 'RATP')
      expect(org.name).to eq('RATP')
      expect(org.updated_at.utc).to be_within(1.second).of Time.now
      expect(org.synced_at.utc).to be_within(1.second).of Time.now
      expect(org.sso_attributes['functional_scope']).to eq "[\"STIF:CODIFLIGNE:Line:C00840\", \"STIF:CODIFLIGNE:Line:C00086\"]"
    end

    it 'should not create organisation if code is already present' do
      create :organisation, code:'RATP'
      expect{Organisation.portail_sync}.to change{ Organisation.count }.by(4)
    end
  end
end
