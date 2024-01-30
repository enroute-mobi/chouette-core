RSpec.describe UsersController, :type => :controller do

  let(:organisation) { @user.organisation }

  [
    [:get, :edit],
    [:post, :update, nil, user: { foo: :bar }],
    [:delete, :destroy],
    [:put, :block],
    [:put, :unblock, ->{ target_user.lock_access! }],
    [:put, :reset_password, ->{ target_user.update(confirmed_at: Time.now) }],
    [:put, :reinvite, ->{ target_user.update(invitation_sent_at: Time.now) }]
  ].each do |verb, action, before, extra_params|
    extra_params ||= {}

    describe "#{verb.to_s.upcase} #{action}" do
      let(:do_request) { send verb, action, params: { id: target_user.id }.update(extra_params) }
      let(:target_user) { create :user }

      it 'should be forbidden' do
        do_request
        expect(response.status).to eq 302
      end

      context 'logged in' do
        before(:each) do
          @request.env["devise.mapping"] = Devise.mappings[:user]
          user_organisation = Organisation.where(:code => "first").first_or_create(attributes_for(:organisation))
          @user = create(:user, organisation: user_organisation, profile: profile)
          sign_in @user

          controller.request.env["HTTP_REFERER"] = "/organisation/users/#{target_user.id}"
          instance_exec &before if before
        end

        context 'in the same organisation' do
          let(:target_user)  { create :user, organisation: organisation }

          context 'as visitor' do
            let(:profile){ :visitor }
            it 'should be forbidden' do
              do_request
              expect(response.status).to eq 403
            end
          end

          context 'as editor' do
            let(:profile){ :editor }
            it 'should be forbidden' do
              do_request
              expect(response.status).to eq 403
            end
          end

          context 'as admin' do
            let(:profile){ :admin }
            it 'should be authorized' do
              do_request
              expect(response.status).to eq (verb == :get ? 200 : 302)
            end
          end
        end

        context 'in a different organisation' do
          let(:target_user)  { create :user, organisation: create(:organisation) }

          context 'as visitor' do
            let(:profile){ :visitor }
            it 'should be forbidden' do
              expect(do_request).to render_template('errors/not_found')
            end
          end

          context 'as editor' do
            let(:profile){ :editor }
            it 'should be forbidden' do
              expect(do_request).to render_template('errors/not_found')
            end
          end

          context 'as admin' do
            let(:profile){ :admin }
            it 'should be authorized' do
              expect(do_request).to render_template('errors/not_found')
            end
          end
        end
      end
    end
  end

  [
    [:get, :edit],
    [:post, :update, nil, user: { foo: :bar }],
    [:delete, :destroy],
    [:put, :block]
  ].each do |verb, action, before, extra_params|
    extra_params ||= {}

    describe "#{verb.to_s.upcase} #{action}" do
      let(:do_request){ send verb, action, params: { id: target_user.id }.update(extra_params) }

      before(:each) do
        @request.env["devise.mapping"] = Devise.mappings[:user]
        user_organisation = Organisation.where(:code => "first").first_or_create(attributes_for(:organisation))
        @user = create(:user, organisation: user_organisation, profile: profile)
        sign_in @user

        controller.request.env["HTTP_REFERER"] = "/organisation/users/#{target_user.id}"
        instance_exec &before if before
      end
      let(:target_user)  { create :user, organisation: organisation }

      context 'on self' do
        let(:target_user)  { @user }

        Permission::Profile.each do |user_profile|
          context "as #{user_profile}" do
            let(:profile){ user_profile }
            it 'should be forbidden' do
              do_request
              expect(response.status).to eq 403
            end
          end
        end
      end
    end
  end
end
