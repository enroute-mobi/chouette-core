RSpec.describe Api::V1::NetexImportController, type: :controller do
  let( :netex_import ){ build_stubbed :netex_import }

  it_behaves_like "api key protected controller" do
    let(:data){ netex_import }
  end

  describe "POST #create" do

  end

end
