RSpec.describe Api::V1::ImportsController do
  describe "routing" do
    it { 
        expect(post: '/api/v1/imports').to route_to(
          controller: 'api/v1/imports',
          action: 'create'
        ) 
    }
  end
end
