
RSpec.describe ErrorsController, type: :controller do
  login_user

  describe 'GET not_found' do
    before(:each) { get 'not_found' }

    it 'renders the not_found template' do
      expect(response).to render_template('not_found')
    end

    it 'returns 404 status code' do
      expect(response).to have_http_status(404)
    end
  end

  describe 'GET forbidden' do
    before(:each) { get 'forbidden' }

    it 'renders the forbidden template' do
      expect(response).to render_template('forbidden')
    end

    it 'returns 403 status code' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET server_error' do
    before(:each) { get 'server_error' }

    it 'renders the server_error template' do
      expect(response).to render_template('server_error')
    end

    it 'returns 500 status code' do
      expect(response).to have_http_status(500)
    end
  end
end
