require 'spec_helper'

RSpec.describe WorkbenchesController, :type => :controller do
  let(:workbench) { create :workbench }

  describe "GET show" do
    it "returns http success" do
      get :show, id: workbench.id
      expect(response).to have_http_status(302)
    end
  end

end
