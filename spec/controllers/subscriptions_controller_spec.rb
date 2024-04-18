# frozen_string_literal: true

RSpec.describe SubscriptionsController, type: :controller do
  let(:params){{
    user_name: "foo",
    organisation_name: "bar"
  }}

  let(:resource){ assigns(:subscription)}

  describe "POST create" do
    before(:each) do
      allow(Subscription).to receive(:enabled?) { false }
    end

    it "should be not found" do
      post :create, params: { subscription: params }
      expect(response).to have_http_status 404
    end

    context "with the feature enabled" do
      before(:each) do
        allow(Subscription).to receive(:enabled?) { true }
      end

      it "should be add errors" do
        post :create, params: { subscription: params }
        expect(response).to have_http_status 200
        expect(resource.errors[:email]).to be_present
      end
    end

    context "with all data set" do
      let(:params) do
        {
          organisation_name: 'organisation_name',
          user_name: 'user_name',
          email: 'email@email.com',
          password: 'password$42',
          password_confirmation: 'password$42'
        }
      end

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
          allow(Subscription).to receive(:enabled?) { true }
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
          allow(Subscription).to receive(:enabled?) { false }

          expect(Subscription.enabled?).to be_falsy
        end
        context 'after_create' do
          it 'should not schedule mailer' do
            expect(SubscriptionMailer).to_not receive(:created)
            post :create, params: { subscription: params }
          end
        end
      end
    end
  end
end
