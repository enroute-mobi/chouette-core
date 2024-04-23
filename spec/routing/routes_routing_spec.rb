# frozen_string_literal: true

RSpec.describe 'routes for Routes', type: :routing do
  context 'routes /workbenches/:workbench_id/referentials/:id/lines/:id/routes/:id/duplicate' do
    let(:controller) do
      {
        controller: 'routes',
        workbench_id: ':workbench_id',
        referential_id: ':referential_id',
        line_id: ':line_id',
        id: ':id'
      }
    end

    it 'with method post to #post_duplicate' do
      expect(
        post: '/workbenches/:workbench_id/referentials/:referential_id/lines/:line_id/routes/:id/duplicate'
      ).to route_to controller.merge(action: 'duplicate')
    end
  end
end
