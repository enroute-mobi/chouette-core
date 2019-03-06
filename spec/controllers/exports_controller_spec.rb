RSpec.describe ExportsController, :type => :controller do
  login_user

  let(:organisation){ @user.organisation }
  let(:workbench) { create :workbench, organisation: organisation }
  let(:export)    { create(:netex_export, workbench: workbench, referential: first_referential) }

  describe "GET index" do
    let(:request){ get :index, workbench_id: workbench.id }
    it_behaves_like 'checks current_organisation'
  end

  describe 'GET #new' do
    it 'should be successful if authorized' do
      get :new, workbench_id: workbench.id
      expect(response).to be_success
    end

    it 'should be unsuccessful unless authorized' do
      remove_permissions('exports.create', from_user: @user, save: true)
      get :new, workbench_id: workbench.id
      expect(response).not_to be_success
    end
  end

  describe "POST #create" do
    let(:params){ {name: "foo"} }
    let(:request){ post :create, workbench_id: workbench.id, export: params  }
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
        expect{request}.to change{Export::Netex.count}.by(1)
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
        post :upload, workbench_id: workbench.id, id: export.id, token: export.token_upload
        expect(response).to be_success
      end
    end

    context "without the token" do
      it 'should be unsuccessful' do
        post :upload, workbench_id: workbench.id, id: export.id, token: "foo"
        expect(response).to_not be_success
      end
    end
  end
end
