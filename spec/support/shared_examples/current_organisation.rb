# frozen_string_literal: true

RSpec.shared_examples_for 'checks current_organisation' do
  context 'when belonging the the correct organisation' do
    it 'should succeed' do
      expect(request).to have_http_status(:ok)
    end
  end

  context "when belonging the the wrong organisation" do
    let(:user_organisation) { create(:organisation) }

    it 'should respond with NOT FOUND' do
      expect(request).to render_template('errors/not_found')
    end
  end
end
