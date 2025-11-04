# frozen_string_literal: true

RSpec.describe UsersController, type: :controller do
  [
    [:get, :edit],
    [:post, :update, nil, user: { foo: :bar }],
    [:delete, :destroy],
    [:put, :block],
    [:put, :unblock, ->{ target_user.lock_access! }],
    [:put, :reset_password, ->{ target_user.update(confirmed_at: Time.now) }],
    [:put, :reinvite, ->{ target_user.update(invitation_sent_at: Time.now) }]
  ].each do |verb, action, before = nil, extra_params = {}|
    describe "#{verb.to_s.upcase} #{action}" do
      let(:do_request) { send verb, action, params: { id: target_user.id }.update(extra_params) }
      let(:target_user) { create :user }

      it 'should be forbidden' do
        do_request
        expect(response).to redirect_to(new_user_session_url)
      end

      context 'logged in' do
        login_user

        before(:each) do
          controller.request.env["HTTP_REFERER"] = "/organisation/users/#{target_user.id}"
          instance_exec &before if before
        end

        context 'in the same organisation' do
          let(:target_user)  { create :user, organisation: organisation }

          context 'as visitor' do
            let(:profile){ :visitor }
            it 'should be forbidden' do
              do_request
              expect(response).to have_http_status(:forbidden)
            end
          end

          context 'as editor' do
            let(:profile){ :editor }
            it 'should be forbidden' do
              do_request
              expect(response).to have_http_status(:forbidden)
            end
          end

          context 'as admin' do
            let(:profile){ :admin }
            it 'should be authorized' do
              do_request
              if verb == :get
                expect(response).to have_http_status(:ok)
              elsif action == :destroy
                expect(response).to redirect_to(organisation_url)
              else
                expect(response).to redirect_to(organisation_user_url(target_user.id))
              end
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
  ].each do |verb, action, before = nil, extra_params = {}|
    describe "#{verb.to_s.upcase} #{action}" do
      login_user

      let(:do_request){ send verb, action, params: { id: target_user.id }.update(extra_params) }

      before(:each) do
        controller.request.env["HTTP_REFERER"] = "/organisation/users/#{target_user.id}"
        instance_exec &before if before
      end
      let(:target_user)  { create :user, organisation: organisation }

      context 'on self' do
        let(:target_user) { current_user }

        Permission::Profile.each do |user_profile|
          context "as #{user_profile}" do
            let(:profile){ user_profile }
            it 'should be forbidden' do
              do_request
              expect(response).to have_http_status(:forbidden)
            end
          end
        end
      end
    end
  end
end
