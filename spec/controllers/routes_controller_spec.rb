# frozen_string_literal: true

RSpec.describe RoutesController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        referential do
          route
        end

        stop_area :zdep, name: 'ecola', area_type: 'zdep'
        stop_area :lda, area_type: 'lda'
      end
    end
  end

  let!(:referential) { context.referential }
  let!(:line) { context.referential.lines.first }
  let!(:route) { context.route }
  let(:zdep) { context.stop_area(:zdep) }
  let(:lda) { context.stop_area(:lda) }

  it { is_expected.to be_kind_of(ChouetteController) }

  shared_examples_for 'line and referential linked' do
    it 'assigns route.line as @line' do
      expect(assigns[:line]).to eq(route.line)
    end

    it 'assigns referential as @referential' do
      expect(assigns[:referential]).to eq(referential)
    end
  end

  shared_examples_for 'route, line and referential linked' do
    it 'assigns route as @route' do
      expect(assigns[:route]).to eq(route)
    end
    it_behaves_like 'line and referential linked'
  end

  describe 'GET /index' do
    before(:each) do
      get :index, params: {
        line_id: route.line_id,
        referential_id: referential.id
      }
    end

    it_behaves_like 'line and referential linked'
  end

  describe 'POST /create' do
    before(:each) do
      post :create, params: {
        line_id: route.line_id,
        referential_id: referential.id,
        route: { name: 'changed' }
      }
    end
    it_behaves_like 'line and referential linked'
    it 'sets metadata' do
      expect(Chouette::Route.last.metadata.creator_username).to eq @user.username
    end
  end

  describe 'PUT /update' do
    let(:request)  do
      put :update, params: {
        id: route.id, line_id: route.line_id,
        referential_id: referential.id,
        route: route.attributes.update({ 'name' => 'New name' })
      }
    end
    context '' do
      before { request }
      it_behaves_like 'route, line and referential linked'
      it 'sets metadata' do
        expect(Chouette::Route.last.metadata.modifier_username).to eq @user.username
      end
    end
    it 'does not save item twice' do
      counts = Hash.new { |hash, key| hash[key] = 0 }
      allow_any_instance_of(Chouette::Route).to receive(:save).and_wrap_original do |meth, *args|
        counts[meth.receiver.id] += 1
        meth.call(*args)
      end
      request
      expect(counts.size).to eq 1
      expect(counts[route.id]).to eq 1
    end
  end

  describe 'GET /show' do
    before(:each) do
      get :show, params: {
        id: route.id,
        line_id: route.line_id,
        referential_id: referential.id
      }
    end

    it_behaves_like 'route, line and referential linked'
  end

  describe 'POST /duplicate' do
    before do
      referential.switch # Force referential switch because spec/support/referential.rb force referential switch to use first
    end

    it 'creates a new route' do
      expect do
        post :duplicate, params: {
          referential_id: referential.id,
          line_id: route.line_id,
          id: route.id
        }
      end.to change { Chouette::Route.count }.by(1)

      expect(Chouette::Route.last.name).to eq(I18n.t('activerecord.copy', name: route.name))
      expect(Chouette::Route.last.published_name).to eq(route.published_name)
      expect(Chouette::Route.last.stop_area_ids).to eq route.stop_area_ids
    end

    context 'when opposite = true' do
      it 'creates a new route on the opposite way' do
        expect do
          post :duplicate, params: {
            referential_id: referential.id,
            line_id: route.line_id,
            id: route.id,
            opposite: true
          }
        end.to change { Chouette::Route.count }.by(1)

        new_route = Chouette::Route.last
        expect(new_route.name).to eq(I18n.t('routes.opposite', name: route.name))
        expect(new_route.published_name).to eq(new_route.published_name)
        expect(new_route.opposite_route).to eq(route)
        expect(new_route.stop_area_ids).to eq route.stop_area_ids.reverse
      end
    end
  end

  describe 'GET #autocomplete_stop_areas' do
    it 'should be successful' do
      get :autocomplete_stop_areas, params: { referential_id: referential.id, line_id: line.id, id: route.id }
      expect(response).to be_successful
    end

    context 'search by name' do
      it 'should be successful' do
        get :autocomplete_stop_areas,
            params: { referential_id: referential.id, line_id: line.id, id: route.id, q: 'écolà', format: :json }
        expect(response).to be_successful
        expect(assigns(:stop_areas)).to eq([zdep])
      end

      it 'should be accent insensitive' do
        get :autocomplete_stop_areas,
            params: { referential_id: referential.id, line_id: line.id, id: route.id, q: 'ecola', format: :json }
        expect(response).to be_successful
        expect(assigns(:stop_areas)).to eq([zdep])
      end
    end

    describe 'without feature route_stop_areas_all_types' do
      let(:scope) { :route_editor }
      let(:request) do
        get :autocomplete_stop_areas,
            params: { referential_id: referential.id, line_id: line.id, id: route.id, scope: scope }
      end

      it 'should filter stop areas based on type' do
        request
        expect(assigns(:stop_areas)).to include(zdep)
        expect(assigns(:stop_areas)).to_not include(lda)
      end

      it 'should filter stop areas based on type if we change the default behaviour' do
        referential.stop_area_referential.route_edition_available_stops = { lda: true }
        referential.stop_area_referential.save
        request
        expect(assigns(:stop_areas)).to include(lda)
        expect(assigns(:stop_areas)).to_not include(zdep)
      end
    end

    describe 'without feature route_stop_areas_all_types' do
      let(:scope) { :route_editor }
      let(:request) do
        get :autocomplete_stop_areas,
            params: { referential_id: referential.id, line_id: line.id, id: route.id, scope: scope }
      end

      with_feature :route_stop_areas_all_types do
        it 'should not filter stop areas based on type' do
          request
          expect(assigns(:stop_areas)).to include(zdep)
          expect(assigns(:stop_areas)).to include(lda)
        end
      end
    end
  end
end
