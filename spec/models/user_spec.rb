require 'spec_helper'

describe User, :type => :model do
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
          :organisation_name => 'af83'
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
