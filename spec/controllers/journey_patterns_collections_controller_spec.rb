# frozen_string_literal: true

RSpec.describe JourneyPatternsCollectionsController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workbench(organisation: Organisation.find_by(code: 'first')) do
        referential do
          route
        end
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }
  let(:line) { route.line }
  let(:route) { context.route }

  let(:base_params) do
    {
      'workbench_id' => workbench.id.to_s,
      'referential_id' => referential.id.to_s,
      'line_id' => line.id.to_s,
      'route_id' => route.id.to_s
    }
  end
  let(:format) { nil }

  describe 'GET show' do
    subject { get :show, params: base_params, format: format }

    context 'in JSON' do
      let(:format) { 'json' }

      it 'should be successful' do
        subject
        expect(response).to be_successful
      end

      it 'sets user permissions' do
        subject

        expect(JSON.parse(assigns(:features))).to be_a(Hash)
        expect(JSON.parse(assigns(:perms))).to eq(
          {
            'journey_patterns.create' => true,
            'journey_patterns.update' => true,
            'journey_patterns.destroy' => true
          }
        )
      end

      it 'when user is not authorized' do
        referential.update(archived_at: Time.zone.now)

        subject

        expect(JSON.parse(assigns(:features))).to be_a(Hash)
        expect(JSON.parse(assigns(:perms))).to eq(
          {
            'journey_patterns.create' => false,
            'journey_patterns.update' => false,
            'journey_patterns.destroy' => false
          }
        )
      end
    end
  end
end
