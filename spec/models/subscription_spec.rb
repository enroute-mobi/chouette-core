RSpec.describe Subscription do
  subject(:subscription) { Subscription.new }

  describe "#organisation" do
    subject { subscription.organisation }

    context "when Subscription organisation_name is 'Organisation Sample'" do
      before { subscription.organisation_name = 'Organisation Sample' }

      it { is_expected.to have_attributes(name: 'Organisation Sample', code: 'organisation-sample') }
    end

    it "has all Features" do
      is_expected.to have_attributes(features: Feature.all)
    end
  end

  describe "#user" do
    subject { subscription.user }

    context "when Subscription user name is 'User Sample'" do
      before { subscription.user_name = 'User Sample' }
      it { is_expected.to have_attributes(name: subscription.user_name) }
    end

    it { is_expected.to have_same_attributes(:email, :password, :password_confirmation, than: subscription)}

    it { is_expected.to have_attributes(profile: "admin") }

    it "associates to the Subscription organisation" do
      is_expected.to have_attributes(organisation: subscription.organisation)
    end
  end

  describe "#workbench_confirmation" do
    subject { subscription.workbench_confirmation }

    context "when Subscription workbench invitation code is defined" do
      before { subscription.workbench_invitation_code = '123456' }

      context "when Subscription workbench invitation code is 'Code Sample'" do
        before { subscription.workbench_invitation_code = 'Code Sample' }
        it { is_expected.to have_attributes(invitation_code: 'Code Sample') }
      end

      it "associates to the Subscription organisation" do
        is_expected.to have_attributes(organisation: subscription.organisation)
      end
    end

    context "when Subscription workbench invitation code isn't defined" do
      before { subscription.workbench_invitation_code = "" }

      it { is_expected.to be_nil }
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:organisation_name) }
    it { is_expected.to validate_presence_of(:user_name) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to_not allow_value("dummy").for(:email) }

    it { is_expected.to validate_presence_of(:password) }

    # validate_confirmation_of refuses to work
    # it { is_expected.to validate_confirmation_of(:password) }
    context "when password confirmation doesn't match" do
      before do
        subscription.password = "some value"
        subscription.password_confirmation = "other value"
      end

      it "an error is present on this attribute" do
        subscription.validate
        expect(subscription.errors[:password_confirmation]).to_not be_empty
      end
    end

    it { is_expected.to_not validate_presence_of(:workbench_invitation_code) }
    it { is_expected.to_not allow_value("dummy").for(:workbench_invitation_code) }
  end

  describe "save" do
    before do
      subscription.attributes = { organisation_name: "Test", user_name: "Test", email: "example@chouette.test" }
      subscription.password = subscription.password_confirmation = "Dummy but Strong"
    end

    context "when Subscription isn't valid" do
      subject { subscription.save }

      before { allow(subscription).to receive(:valid?).and_return(false) }

      it { is_expected.to be_falsy }
    end

    describe "organisation" do
      subject { subscription.organisation }
      it "is created" do
        expect { subscription.save }.to change(subject, :new_record?).from(true).to(false)
      end
    end

    describe "user" do
      subject { subscription.user }
      it "is created" do
        expect { subscription.save }.to change(subject, :new_record?).from(true).to(false)
      end
    end

    describe "mailer" do
      it "is invoked with created user" do
        expect(SubscriptionMailer).to receive(:new_subscription).with(subscription.user)
        subscription.save
      end
    end

    context "when no workbench invitation code is provided" do
      subject { subscription.workgroup }

      before do
        subscription.workbench_invitation_code = ""
      end

      describe "workgroup" do
        it "is created" do
          subscription.save
          is_expected.to be_persisted
        end
      end
    end

    context "when a workbench invitation code is provided" do
      let(:context) do
        Chouette.create { workbench invitation_code: '123456', organisation: nil }
      end
      let(:workbench) { context.workbench }

      before do
        subscription.workbench_invitation_code = "123456"
      end

      it "doesn't create a Workgroup" do
        expect { subscription.save }.to_not change { Workgroup.count }
      end

      describe "workbench" do
        it "is associated to the new Organisation" do
          expect { subscription.save }.to change { workbench.reload.organisation }.from(nil).to(subscription.organisation)
        end
        it "loses its invitation code" do
          expect { subscription.save }.to change { workbench.reload.invitation_code }.from("123456").to(nil)
        end
      end
    end
  end
end
