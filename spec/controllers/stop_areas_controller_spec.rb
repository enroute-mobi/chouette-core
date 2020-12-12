RSpec.describe StopAreasController, :type => :controller do
  login_user

  let!(:context) do
    Chouette.create do
      workgroup do
        workbench organisation: Organisation.find_by_code('first') do
          3.times { stop_area }
        end
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:stop_area_referential) { context.stop_area_referential }
  let(:stop_area_provider) { context.stop_area_provider }
  let(:stop_area) { context.stop_area }

  describe "GET index" do
    it "filters by registration number" do
      matched = stop_area_provider.stop_areas.create name: "Match", registration_number: 'E34'

      get :index, params: {
        workbench_id: workbench,
        q: {
          name_or_objectid_or_registration_number_cont: matched.registration_number
        }
      }

      expect(assigns(:stop_areas)).to eq([matched])
    end

    it "doesn't filter when the name filter is empty" do
      get :index, params: {
        workbench_id: workbench,
        q: {
          name_or_objectid_or_registration_number_cont: ''
        }
      }

      expect(assigns(:stop_areas)).to match_array(stop_area_referential.stop_areas)
    end
  end
end
