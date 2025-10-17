# frozen_string_literal: true

RSpec.describe RoutingConstraintZonesController do
  login_user

  let(:context) do
    organisation = self.organisation
    Chouette.create do
      workbench organisation: organisation do
        referential do
          routing_constraint_zone
        end
      end
    end
  end

  let!(:routing_constraint_zone) { context.routing_constraint_zone }
  let(:route) { context.route }
  let(:referential) { context.referential }
  let(:q) { {} }

  describe 'GET index' do
    let(:request) do
      get :index, params: {
        workbench_id: referential.workbench.id,
        referential_id: referential.id,
        line_id: route.line_id,
        q: q
      }
    end

    before { referential.update objectid_format: :netex }

    it { expect { request }.to raise_error(FeatureChecker::NotAuthorizedError) }

    with_features :legacy_routing_constraint_zone do
      it 'should include the rcz' do
        expect(request).to be_successful
        expect(assigns(:routing_constraint_zones)).to include(routing_constraint_zone)
      end
    end
  end
end
