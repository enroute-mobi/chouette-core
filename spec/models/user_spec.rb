RSpec.describe User, :type => :model do
  # it { should validate_uniqueness_of :email }
  # it { should validate_presence_of :name }

  describe "SSO" do
    let(:ticket) do
      CASClient::ServiceTicket.new("ST-test", nil).tap do |ticket|
        ticket.extra_attributes = {
          :full_name         => 'john doe',
          :username          => 'john.doe',
          :email             => 'john.doe@af83.com',
          :organisation_code => '0083',
          :organisation_name => 'af83',
          :functional_scope  => "[\"STIF:CODIFLIGNE:Line:C00840\", \"STIF:CODIFLIGNE:Line:C00086\"]",
          :permissions       => []
        }
        ticket.user    = "john.doe"
        ticket.success = true
      end
    end

    context 'First time sign on' do
      it 'should create a new user if user is not registered' do
        expect{User.authenticate_with_cas_ticket(ticket)}.to change{ User.count }
        user = User.find_by(username: 'john.doe')
        expect(user.email).to eq(ticket.extra_attributes[:email])
        expect(user.name).to  eq(ticket.extra_attributes[:full_name])
      end

      it 'should create a new organisation if organisation is not present' do
        expect{User.authenticate_with_cas_ticket(ticket)}.to change{ Organisation.count }
        expect(Organisation.find_by(code: ticket.extra_attributes[:organisation_code])).to be_truthy
      end

      it 'should store organisation functional_scope' do
        User.authenticate_with_cas_ticket(ticket)
        org = Organisation.find_by(code: ticket.extra_attributes[:organisation_code])
        expect(org.sso_attributes['functional_scope']).to eq "[\"STIF:CODIFLIGNE:Line:C00840\", \"STIF:CODIFLIGNE:Line:C00086\"]"
      end

      it 'should update organisation functional_scope' do
        create :organisation, code: ticket.extra_attributes[:organisation_code], sso_attributes: {functional_scope: "[\"STIF:CODIFLIGNE:Line:C00840\"]"}
        User.authenticate_with_cas_ticket(ticket)
        org = Organisation.find_by(code: ticket.extra_attributes[:organisation_code])
        expect(org.sso_attributes['functional_scope']).to eq "[\"STIF:CODIFLIGNE:Line:C00840\", \"STIF:CODIFLIGNE:Line:C00086\"]"
      end

      it 'should not create a new organisation if organisation is already present' do
        ticket.extra_attributes[:organisation_code] = create(:organisation).code
        expect{User.authenticate_with_cas_ticket(ticket)}.not_to change{ Organisation.count }
      end
    end

    context 'Update attributes on sign on' do
      let!(:organisation) { create(:organisation) }
      let!(:user) { create(:user, username: 'john.doe', name:'fake name' , email: 'test@example.com', :organisation => organisation) }

      it 'should update user attributes on sign on' do
        User.authenticate_with_cas_ticket(ticket)
        expect(user.reload.email).to eq(ticket.extra_attributes[:email])
        expect(user.reload.name).to  eq(ticket.extra_attributes[:full_name])
      end
    end
  end

  describe "Portail sync" do
    let(:conf) { Rails.application.config.stif_portail_api }
    before :each do
      stub_request(:get, "#{conf[:url]}/api/v1/users").
        with(stub_headers(authorization_token: conf[:key])).
        to_return(body: File.open(File.join(Rails.root, 'spec', 'fixtures', 'users.json')), status: 200)
    end

    it 'should retrieve data from portail api' do
      expect(User.portail_api_request).to be_truthy
      expect(WebMock).to have_requested(:get, "#{conf[:url]}/api/v1/users").
        with(headers: { 'Authorization' => "Token token=\"#{conf[:key]}\"" })
    end

    it 'should create new users' do
      User.portail_sync
      expect(User.count).to eq(12)
      expect(Organisation.count).to eq(3)
    end

    it 'should update existing users' do
      create :user, username: 'alban.peignier', email:'dummy@example.com', updated_at: 10.days.ago
      User.portail_sync
      user = User.find_by(username: 'alban.peignier')

      expect(user.name).to eq('Alban Peignier')
      expect(user.email).to eq('alban.peignier@af83.com')
      expect(user.updated_at.utc).to be_within(1.second).of Time.now
      expect(user.synced_at.utc).to be_within(1.second).of Time.now
    end

    it 'should update organisation assignement' do
      create :user, username: 'alban.peignier', organisation: create(:organisation)
      User.portail_sync
      expect(User.find_by(username: 'alban.peignier').organisation.name).to eq("STIF")
    end

    it 'should update locked_at attribute' do
      create :user, username: 'alban.peignier', locked_at: Time.now
      User.portail_sync
      expect(User.find_by(username: 'alban.peignier').locked_at).to be_nil
      expect(User.find_by(username: 'jane.doe').locked_at).to eq("2016-08-05T12:34:03.995Z")
    end

    it 'should not create new user if username is already present' do
      create :user, username: 'alban.peignier'
      User.portail_sync
      expect(User.count).to eq(12)
    end

    context 'permissions' do
      let( :all_permissions ){ Stif::PermissionTranslator.translate(%w{boiv:edit-offer}) }

      it 'should give edit permissions to user if user has "edit offer" permission in portail' do
        User.portail_sync
          expect(User.find_by(username: 'vlatka.pavisic').permissions).to eq(all_permissions)
        expect(User.find_by(username: 'pierre.vabre').permissions).to be_empty
      end
    end
  end

  describe "#destroy" do
    let!(:organisation){create(:organisation)}
    let!(:user){create(:user, :organisation => organisation)}

    context "user's organisation contains many user" do
      let!(:other_user){create(:user, :organisation => organisation)}

      it "should destoy also user's organisation" do
        user.destroy
        expect(Organisation.where(:name => organisation.name).exists?).to be_truthy
        read_organisation = Organisation.where(:name => organisation.name).first
        expect(read_organisation.users.count).to eq(1)
        expect(read_organisation.users.first).to eq(other_user)
      end
    end
  end
end
