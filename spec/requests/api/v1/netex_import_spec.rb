RSpec.describe "NetexImport", type: :request do

  describe 'POST netex_imports' do

    let( :referential ){ create :referential }

    let( :file_path ){ fixtures_path 'singleref.zip' }
    let( :file ){ fixture_file_upload( file_path ) }

    let( :post_request ) do
      -> (attributes) do
        post "/api/v1/netex_imports.json",
          attributes,
          authorization
      end
    end

    let( :legal_attributes ) do
      {
        name: 'hello world',
        file: file,
        referential_id: referential.id,
        workbench_id:   referential.workbench_id
      }
    end 

    let( :illegal_attributes ) do
      { referential_id: referential.id }
    end 

    context 'with correct credentials and correct request' do
      let( :authorization ){ authorization_token_header( get_api_key.token ) }


      it 'succeeds' do
        post_request.(netex_import: legal_attributes)
        expect( response ).to be_success
        expect( json_response_body ).to eq({'id' => NetexImport.last.id, 'type' => 'NetexImport'})
      end

      it 'creates a NetexImport object in the DB' do
        expect{ post_request.(netex_import: legal_attributes) }.to change{NetexImport.count}.by(1)
      end
    end

    context 'with incorrect credentials and correct request' do
      let( :authorization ){ authorization_token_header( "#{referential.id}-incorrect_token") }

      it 'does not succeed' do
        post_request.(netex_import: legal_attributes)
        expect( response.status ).to eq(401)
      end

      it 'does not create an Import object' do
        expect{ post_request.(netex_import: legal_attributes) }.not_to change{Import.count}
      end
    end

    context 'with correct credentials and incorrect request' do
      let( :authorization ){ authorization_token_header( get_api_key.token ) }

      it 'does not succeed' do
        post_request.(netex_import: illegal_attributes)
        expect( response.status ).to eq(406)
        expect( json_response_body['errors']['file'] ).not_to be_empty
      end

      it 'does not create an Import object' do
        expect{ post_request.(netex_import: illegal_attributes) }.not_to change{Import.count}
      end
    end
  end
end
