RSpec.describe StopAreasController, type: :controller do

  login_user

  let( :stop_area_referential ){ create :stop_area_referential }

  context 'collection' do
    it_should_redirect_to_forbidden 'GET :index', member_model: :stop_area_referential do
      get :index, stop_area_referential_id: stop_area_referential.id
    end

    it_should_redirect_to_forbidden 'GET :new', member_model: :stop_area_referential do
      get :new, stop_area_referential_id: stop_area_referential.id
    end

    it_should_redirect_to_forbidden 'POST :create', ok_status: 302, member_model: :stop_area_referential do
      post :create, stop_area_referential_id: stop_area_referential.id, stop_area: attributes_for( :stop_area )
    end
  end

  context 'member' do 
    let( :stop_area ){ create :stop_area, stop_area_referential: stop_area_referential }

    it_should_redirect_to_forbidden 'GET :show', member_model: :stop_area_referential do
      get :show, stop_area_referential_id: stop_area_referential.id, id: stop_area.id
    end

    it_should_redirect_to_forbidden 'GET :edit', member_model: :stop_area_referential do
      get :edit, stop_area_referential_id: stop_area_referential.id, id: stop_area.id
    end

    it_should_redirect_to_forbidden 'PUT :update', ok_status: 302, member_model: :stop_area_referential do
      put :update, stop_area_referential_id: stop_area_referential.id, id: stop_area.id, stop_area: attributes_for( :stop_area )
    end

    it_should_redirect_to_forbidden 'DELETE :destroy', ok_status: 302, member_model: :stop_area_referential do
      delete :destroy, stop_area_referential_id: stop_area_referential.id, id: stop_area.id
    end
  end
end
