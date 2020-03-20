RSpec.describe ExportsController, :type => :controller do

  login_user

  [:workgroup, :workbench].each do |parent|

    let(:organisation){ @user.organisation }
    let(:workbench) { create :workbench, organisation: organisation }
    let(:export)    { create(:netex_export, workbench: workbench, referential: first_referential) }

    before(:each) do
      stub_request(:get, %r{#{Rails.configuration.iev_url}/boiv_iev*})
    end

    context "with #{parent} parent" do
      let(:parent_params) { parent == :workbench ? {workbench_id: workbench.id}:{workgroup_id: workbench.workgroup_id} }

      describe "GET index" do
        let(:request){ get :index, params: parent_params }
        it_behaves_like 'checks current_organisation'
      end

      describe 'GET #new' do
        it 'should be successful if authorized' do
          byebug
          get :new, params: parent_params
          expect(response).to be_successful
        end

        it 'should be unsuccessful unless authorized' do
          remove_permissions('exports.create', from_user: @user, save: true)
          get :new, params: parent_params
          expect(response).not_to be_successful
        end
      end

      describe "GET #show" do
        it 'should be successful' do
          get :show, params: parent_params.merge({ id: export.id })
          expect(response).to be_successful
        end

        context "in JSON format" do
          let(:export) { create :gtfs_export, workbench: workbench  }
          it 'should be successful' do
            get :show, params: parent_params.merge({ id: export.id, format: :json })
            expect(response).to be_successful
          end
        end
      end

      describe "POST #create" do
        let(:params){ {name: "foo"} }
        let(:request){ post :create, params: parent_params.merge({ export: params })}
        it 'should create no objects' do
          expect{request}.to_not change{Export::Netex.count}
        end

        context "with full params" do
          let(:params){{
            name: "foo",
            type: "Export::Netex",
            duration: 12,
            export_type: :full,
            referential_id: first_referential.id
          }}

          it 'should be successful' do
            expect{request}.to change { Export::Netex.count }.by(1)
          end
        end

        context "with missing options" do
          let(:params){{
            name: "foo",
            type: "Export::Workgroup"
          }}

          it 'should be unsuccessful' do
            expect{request}.to change{Export::Netex.count}.by(0)
          end
        end

        context "with all options" do
          let(:params){{
            name: "foo",
            type: "Export::Workgroup",
            duration: 90,
            referential_id: first_referential.id
          }}

          it 'should be successful' do
            expect{request}.to change{Export::Workgroup.count}.by(1)
          end
        end

        context "with wrong type" do
          let(:params){{
            name: "foo",
            type: "Export::Foo"
          }}

          it 'should be unsuccessful' do
            expect{request}.to raise_error ActiveRecord::SubclassNotFound
          end
        end
      end

      describe 'POST #upload' do
        context "with the token" do
          it 'should be successful' do
            post :upload, params: parent_params.merge({ id: export.id, token: export.token_upload })
            expect(response).to be_successful
          end
        end

        context "without the token" do
          it 'should be unsuccessful' do
            post :upload, params: parent_params.merge({ id: export.id, token: "foo" })
            expect(response).to_not be_successful
          end
        end
      end

    end
  end

end
