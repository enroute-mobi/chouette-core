RSpec.describe Api::V1::NetexImportController, type: :controller do

  context 'POST create' do

    let( :netex_import ){ build_stubbed(:netex_import) }

    it 'creates a NetexImport record' do
      expect_any_instance_of( ImportController ).to receive(:create).with(
        params: netex_import.attributes
      )
      
    end
  end

end
