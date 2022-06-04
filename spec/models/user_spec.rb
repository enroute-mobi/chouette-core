RSpec.describe User, :type => :model do
  # it { should validate_uniqueness_of :email }
  # it { should validate_presence_of :name }
  it { should enumerize(:user_locale).in(*I18n.available_locales) }

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

    context "opeations that belong to user" do
      let!(:import) { create :import,  user: user}
      let!(:export) { create :export, user: user, type: 'Export::Gtfs' }
      let!(:ccset) { create :compliance_check_set, user: user }
      let(:workbench) { create :workbench, organisation: user.organisation }
      let(:ref1) {create :referential, workbench: workbench, organisation: user.organisation}
      let(:ref2) {create :referential, workbench: workbench, organisation: user.organisation}
      let!(:merge) { create :merge, user: user, referential_ids: [ref1.id] }
      let!(:aggregate) { Aggregate.create(workgroup: workbench.workgroup, referentials: [ref1, ref2], user: user) }

      it "should nullify their #user_id" do
        user.destroy
        [import, export, ccset, merge, aggregate].each { |operation| expect(operation.reload.user_id).to be_nil }
      end
    end
  end

  describe '#invite' do
    let(:organisation) { create :organisation }
    let(:from_user) { create :user, organisation: organisation }

    it 'should send an email' do
      expect(UserMailer).to receive(:invitation_from_user).and_return(double(deliver_now: true))
      expect(DeviseMailer).to_not receive(:invitation_instructions)
      expect(DeviseMailer).to_not receive(:confirmation_instructions)
      res = User.invite(email: 'foo@example.com', name: 'foo', profile: :admin, organisation: organisation, from_user: from_user)
      expect(res.first).to be_falsy
      expect(res.last).to be_a(User)
      expect(res.last.reload.state).to eq :invited
    end

    context 'when the user alredy exists in the same organisation' do
      before(:each) do
        create :user, email: 'foo@example.com', organisation: organisation
      end

      it 'should not send an email' do
        expect(UserMailer).to_not receive(:invitation_from_user)
        res = User.invite(email: 'foo@example.com', name: 'foo', profile: :admin, organisation: organisation, from_user: from_user)
        expect(res.first).to be_truthy
        expect(res.last).to be_a User
      end
    end

    context 'when the user alredy exists in a different organisation' do
      before(:each) do
        create :user, email: 'foo@example.com'
      end

      it 'should not send an email' do
        expect(UserMailer).to_not receive(:invitation_from_user)
        res = User.invite(email: 'foo@example.com', name: 'foo', profile: :admin, organisation: organisation, from_user: from_user)
        expect(res.first).to be_truthy
        expect(res.last).to be_nil
      end
    end
  end

  let(:user) { build :user, permissions: [] }
  describe '#profile' do
    it 'should be :custom by default' do
      expect(user.profile).to eq 'custom'
    end

    it 'should match the given profiles' do
      Permission::Profile.each do |profile|
        user.profile = profile
        expect(user.profile).to eq profile.to_s
        expect(user.permissions).to eq Permission::Profile.permissions_for(profile)
        user.permissions.pop
        user.validate
        expect(user.profile).to eq 'custom'
      end
    end
  end

  describe '#with_states' do
    let(:pending)   { create :user, confirmed_at: nil, invitation_sent_at: nil, locked_at: nil }
    let(:invited)   { create :user, confirmed_at: Time.now, invitation_sent_at: Time.now, invitation_accepted_at: nil, locked_at: nil }
    let(:confirmed) { create :user, confirmed_at: Time.now, invitation_sent_at: Time.now, invitation_accepted_at: Time.now, locked_at: nil }
    let(:other_confirmed) { create :user, confirmed_at: Time.now, invitation_sent_at: nil, invitation_accepted_at: nil, locked_at: nil }
    let(:blocked)   { create :user, confirmed_at: nil, invitation_sent_at: nil, locked_at: Time.now }

    it 'should find correct states' do
      expect(pending.state).to eq :pending
      expect(invited.state).to eq :invited
      expect(confirmed.state).to eq :confirmed
      expect(other_confirmed.state).to eq :confirmed
      expect(blocked.state).to eq :blocked
    end

    it 'should match correct users' do
      expect(User.with_states(:pending)).to match_array [pending]
      expect(User.with_states(:invited)).to match_array [invited]
      expect(User.with_states(:confirmed)).to match_array [confirmed, other_confirmed]
      expect(User.with_states(:blocked)).to match_array [blocked]
      expect(User.with_states(:pending, :invited)).to match_array [pending, invited]
      expect(User.with_states(:invited, :invited)).to match_array [invited]
    end
  end

  describe '#with_profiles' do
    let(:admin)   { create :user, profile: :admin, name: :admin }
    let(:visitor) { create :user, profile: :visitor, name: :visitor }
    let(:editor)  { create :user, profile: :editor, name: :editor }
    let(:custom)  { create :user, profile: :custom, name: :custom }

    it 'should match correct users' do
      expect(User.with_profiles(:admin)).to match_array [admin]
      expect(User.with_profiles(:visitor)).to match_array [visitor]
      expect(User.with_profiles(:admin, :visitor)).to match_array [admin, visitor]
      expect(User.with_profiles(:admin, :custom)).to match_array [admin, custom]
      expect(User.with_profiles(:custom)).to match_array [custom]
    end
  end

  describe "#with_random_password" do
    subject { User.new.with_random_password }

    let(:random_format) { /[a-zA-Z0-9]{30}/ }

    it {
      is_expected.to have_attributes(
                       password: a_string_matching(random_format),
                       password_confirmation: a_string_matching(random_format))
    }
  end

end
