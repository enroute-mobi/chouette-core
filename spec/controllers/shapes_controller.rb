RSpec.describe ShapesController, :type => :controller do

  let(:context) do
    Chouette.create do
      shape :first
      shape :second
    end
  end

  login_user

  before do
    @user.update_attributes(organisation_id: context.workbench.organisation_id)
  end

  describe "GET index" do

    it 'should be successful' do
      get :index, params: { workbench_id: context.workbench.id }
      expect(response).to be_successful
      expect(assigns(:shapes)).to include(context.shape(:first))
      expect(assigns(:shapes)).to include(context.shape(:second))
    end

    context "with filters" do
      let(:title_or_content_cont){ line_notices.first.title }
      let(:lines_id_eq){ line_notices.last.lines.first.id }

      it "should filter on name or uuid" do
        get :index, params: {  workbench_id: context.workbench.id, q: {name_or_uuid_cont: context.shape(:first).name} }
        expect(response).to be_successful
        expect(assigns(:shapes)).to include(context.shape(:first))
        expect(assigns(:shapes)).to_not include(context.shape(:second))
      end
    end
  end

  describe "GET show" do
    it 'should be successful' do
      get :show, params: { workbench_id: context.workbench.id , id: context.shape(:first).id }
      expect(response).to be_successful
    end
  end

  describe 'GET #edit' do
    it 'should be successful' do
      get :edit, params: { workbench_id: context.workbench.id, id: context.shape(:first).id }
      expect(response).to be_successful
    end
  end

  describe 'POST #update' do
    it 'should be successful' do
      post :update, params: {
        workbench_id: context.workbench.id,
        id: context.shape(:first).id,
        shape: {name: "test again"}
      }
      expect(response).to redirect_to workbench_shape_referential_shape_path(context.workbench, context.shape(:first).id)
    end
  end

  describe 'DELETE #destroy' do
    it 'should be successful' do
      expect {
        delete :destroy, params: { workbench_id: context.workbench.id, id: context.shape(:first).id }
      }.to change(Shape, :count).by(-1)
      expect(response).to redirect_to  workbench_shape_referential_shapes_path(context.workbench)
    end
  end
end
