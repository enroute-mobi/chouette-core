# coding: utf-8

RSpec.describe AutocompleteStopAreasController, type: :controller do
  login_user

  let(:referential) { Referential.first }
  let(:other_referential) { create :referential }
  let!(:stop_area) { create :stop_area, name: 'écolà militaire', referential: referential }
  let!(:other_referential_stop_area) { create :stop_area, name: 'écolà militaire', referential: other_referential }
  let!(:zdep_stop_area) { create :stop_area, area_type: "zdep", referential: referential }
  let!(:not_zdep_stop_area) { create :stop_area, area_type: "lda", referential: referential }

  before(:each) do
    allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
  end

  describe 'GET #index' do
    it 'should be successful' do
      get :index, params: { referential_id: referential.id }
      expect(response).to be_successful
    end

    it "should filter stop areas based on referential" do
      get :index, params: { referential_id: referential.id }
      expect(assigns(:stop_areas)).to include(stop_area)
      expect(assigns(:stop_areas)).to_not include(other_referential_stop_area)
    end

    context 'search by name' do
      it 'should be successful' do
        get :index, params: { referential_id: referential.id, q: 'écolà', :format => :json }
        expect(response).to be_successful
        expect(assigns(:stop_areas)).to eq([stop_area])
      end

      it 'should be accent insensitive' do
        get :index, params: { referential_id: referential.id, q: 'ecola', :format => :json }
        expect(response).to be_successful
        expect(assigns(:stop_areas)).to eq([stop_area])
      end
    end
  end

  context "when searching from the route editor" do
    let(:scope) { :route_editor }
    let(:request){
      get :index, params: { referential_id: referential.id, scope: scope }
    }
    it "should filter stop areas based on type" do
      request
      expect(assigns(:stop_areas)).to include(zdep_stop_area)
      expect(assigns(:stop_areas)).to_not include(not_zdep_stop_area)
    end

    it "should filter stop areas based on type if we change the default behaviour" do
      referential.stop_area_referential.route_edition_available_stops = {lda: true}
      referential.stop_area_referential.save
      request
      expect(assigns(:stop_areas)).to include(not_zdep_stop_area)
      expect(assigns(:stop_areas)).to_not include(zdep_stop_area)
    end

    with_feature :route_stop_areas_all_types do
      it "should not filter stop areas based on type" do
        request
        expect(assigns(:stop_areas)).to include(zdep_stop_area)
        expect(assigns(:stop_areas)).to include(not_zdep_stop_area)
      end
    end
  end


end
