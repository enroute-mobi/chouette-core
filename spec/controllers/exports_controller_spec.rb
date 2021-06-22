RSpec.describe ExportsController, :type => :controller do

  login_user

  let(:context) do
      Chouette.create do
        # To match organisation used by login_user
        organisation = Organisation.find_by_code('first')
        workgroup owner: organisation, export_types: ['Export::Gtfs'] do
          workbench organisation: organisation do
            referential
          end
        end
      end
    end

    let(:referential) { context.referential }
    let(:export) { Export::Gtfs.create!(name: "Test", creator: 'test', referential: referential, workgroup: workgroup, workbench: workbench) }

    let(:workbench) { referential.workbench }
    let(:workgroup) { referential.workgroup }

    context "with #{parent} parent" do
      let(:parent_params) { { workbench_id: workbench.id, workgroup_id: workbench.workgroup_id } }

      describe "GET index" do
        let(:request){ get :index, params: parent_params }

        it "should be successful" do
          expect(request).to be_successful
        end
      end

      describe 'GET #new' do
        it 'should be successful if authorized' do
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
        let(:params){ { name: "foo" } }
        let(:request){ post :create, params: parent_params.merge({ export: params })}
        it 'should create no objects' do
          expect{request}.to_not change{Export::Gtfs.count}
        end

        context "with all options" do
          let(:params){parent_params.merge({
            name: "foo",
            type: "Export::Gtfs",
            referential_id: first_referential.id,
            creator: 'Test',
            options: { duration: 12 }
          })}

          it 'should be successful' do
            expect{request}.to change { Export::Gtfs.count }.by(1)
          end
        end

        context "with missing options" do
          let(:params){{
            referential_id: first_referential.id,
            type: "Export::Gtfs"
          }}

          it 'should be unsuccessful' do
            expect{request}.to change{Export::Gtfs.count}.by(0)
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
