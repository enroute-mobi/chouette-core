RSpec.describe Api::V1::AccessLinksController, type: :controller do
  
  it 'routes to index' do
    expect( get: '/api/v1/access_links' ).to route_to(
      controller: 'api/v1/access_links',
      action: 'index'
    )
  end
end
