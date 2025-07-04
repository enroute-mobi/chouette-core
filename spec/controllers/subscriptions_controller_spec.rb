# frozen_string_literal: true

RSpec.describe SubscriptionsController, type: :controller do
  let(:email) { 'email@email.com' }
  let(:workbench_invitation_code) { '' }

  let(:params) do
    {
      organisation_name: 'organisation_name',
      user_name: 'user_name',
      email: email,
      password: 'password$42',
      password_confirmation: 'password$42',
      workbench_invitation_code: workbench_invitation_code
    }
  end
  let(:resource){ assigns(:subscription)}

  describe "POST create" do
    subject { post :create, params: { subscription: params } }

    context 'with Subscription enabled' do
      before(:each) do
        allow(Subscription).to receive(:enabled?) { true }
      end

      it "should create models and redirect to home" do
        counted = [User, Organisation, LineReferential, StopAreaReferential, Workbench, Workgroup]
        counts = counted.map(&:count)
        post :create, params: { subscription: params }

        expect(response).to redirect_to "/"
        counted.map(&:count).each_with_index do |v, i|
          expect(v).to eq(counts[i] + 1), "#{counted[i].t} count is wrong (#{counts[i] + 1} expected, got #{v})"
        end
      end

      context "when notifications are enabled" do
        before(:each) do
          allow(SubscriptionMailer).to receive(:recipients) { ['test@enroute.mobi'] }
        end
        context 'after_create' do
          it 'should schedule mailer' do
            expect(SubscriptionMailer).to receive(:created).and_call_original
            post :create, params: { subscription: params }
          end
        end
      end

      context "when notifications are disabled" do
        before(:each) do
          allow(SubscriptionMailer).to receive(:recipients) { [] }
        end

        context 'after_create' do
          it 'should not schedule mailer' do
            expect(SubscriptionMailer).to_not receive(:created)
            post :create, params: { subscription: params }
          end
        end
      end

      context 'with invalid params' do
        let(:email) { '' }

        it 'should require email' do
          subject
          expect(response).to have_http_status 200
          expect(resource.errors[:email]).to be_present
        end
      end
    end

    context 'with Subscription disabled' do
      before(:each) do
        allow(Subscription).to receive(:enabled?) { false }
      end

      it 'should require workbench_invitation_code' do
        subject
        expect(response).to have_http_status 200
        expect(resource.errors[:workbench_invitation_code]).to be_present
      end

      context 'with a valid workbench_invitation_code' do
        let(:workbench) do
          Chouette.create do
            workbench invitation_code: 'W-123-456-789'
          end.workbench.tap do |w|
            w.update(organisation: nil)
          end
        end

        let(:workbench_invitation_code) { workbench.invitation_code }

        it 'should create the subscription' do
          subject
          expect(response).to redirect_to workbench_path(workbench)
          expect(User.count).to eq 1
        end
      end
    end
  end
end
