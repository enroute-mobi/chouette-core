RSpec.describe RoutesController, type: :controller do
  login_user

  let(:route) { create(:route, referential: referential) }

  it { is_expected.to be_kind_of(ChouetteController) }

  shared_examples_for "redirected to referential_line_path(referential,line)" do
    it "should redirect_to referential_line_path(referential,line)" do
      # expect(response).to redirect_to( referential_line_path(referential,route.line) )
    end
  end

  shared_examples_for "line and referential linked" do
    it "assigns route.line as @line" do
      expect(assigns[:line]).to eq(route.line)
    end

    it "assigns referential as @referential" do
      expect(assigns[:referential]).to eq(referential)
    end
  end

  shared_examples_for "route, line and referential linked" do
    it "assigns route as @route" do
      expect(assigns[:route]).to eq(route)
    end
    it_behaves_like "line and referential linked"
  end

  describe "GET /index" do
    before(:each) do
      get :index, params: {
        line_id: route.line_id,
        referential_id: referential.id
      }
    end

    it_behaves_like "line and referential linked"
    it_behaves_like "redirected to referential_line_path(referential,line)"
  end

  describe "POST /create" do
    before(:each) do
      post :create, params: {
        line_id: route.line_id,
        referential_id: referential.id,
        route: { name: "changed" }
      }
    end
    it_behaves_like "line and referential linked"
    it_behaves_like "redirected to referential_line_path(referential,line)"
    it "sets metadata" do
      expect(Chouette::Route.last.metadata.creator_username).to eq @user.username
    end
  end

  describe "PUT /update" do
    let(:request){
      put :update, params: {
        id: route.id, line_id: route.line_id,
        referential_id: referential.id,
        route: route.attributes.update({'name' => "New name"})
      }
    }
    context "" do
      before{ request }
      it_behaves_like "route, line and referential linked"
      it_behaves_like "redirected to referential_line_path(referential,line)"
      it "sets metadata" do
        expect(Chouette::Route.last.metadata.modifier_username).to eq @user.username
      end
    end
    it "does not save item twice" do
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

  describe "GET /show" do
    before(:each) do
      get :show, params: {
        id: route.id,
        line_id: route.line_id,
        referential_id: referential.id
      }
    end

    it_behaves_like "route, line and referential linked"
  end

  describe "POST /duplicate" do
    let!( :route_prime ){ route }

    it "creates a new route" do
      expect do
        post :duplicate, params: {
          referential_id: route.line.line_referential_id,
          line_id: route.line_id,
          id: route.id
        }
      end.to change { Chouette::Route.count }.by(1)

      expect(Chouette::Route.last.name).to eq(I18n.t('activerecord.copy', name: route.name))
      expect(Chouette::Route.last.published_name).to eq(route.published_name)
      expect(Chouette::Route.last.stop_area_ids).to eq route.stop_area_ids
    end

    context "when opposite = true" do
      before do
        @positions = Hash[*route.stop_points.map{|sp| [sp.id, sp.position]}.flatten]
      end
      it "creates a new route on the opposite way " do
        expect do
          post :duplicate, params: {
            referential_id: route.line.line_referential_id,
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
        route.reload.stop_points.each do |sp|
          expect(sp.position).to eq @positions[sp.id]
        end
      end
    end

    context "on a duplicated route" do
      let!(:duplicated){ route.duplicate }
      it "creates a new route on the opposite way " do
        expect do
          post :duplicate, params: {
            referential_id: duplicated.line.line_referential_id,
            line_id: duplicated.line_id,
            id: duplicated.id,
            opposite: true
          }
        end.to change { Chouette::Route.count }.by(1)

        expect(Chouette::Route.last.name).to eq(I18n.t('routes.opposite', name: duplicated.name))
        expect(Chouette::Route.last.published_name).to eq(Chouette::Route.last.published_name)
        expect(Chouette::Route.last.opposite_route).to eq(duplicated)
        expect(Chouette::Route.last.stop_area_ids).to eq duplicated.stop_area_ids.reverse
      end
    end
  end
end
