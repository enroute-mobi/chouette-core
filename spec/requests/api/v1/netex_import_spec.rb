RSpec.describe "NetexImport", type: :request do

  describe 'POST netex_imports' do

    let( :referential ){ create :referential }

    let( :file_path ){'spec/fixtures/neptune.zip'}
    let( :file ){ fixture_file_upload( file_path ) }

    let( :post_request ) do
      -> do
        post "/api/v1/netex_imports.json",
          attributes,
          authorization
      end
    end

    let( :attributes ){ {
      netex_import: {
        name: 'hello world',
        file: file,
        referential_id: referential.id}
    } }

    context 'with correct credentials and correct request' do
      let( :authorization ){ authorization_token_header( get_api_key.token ) }


      it 'succeeds' do
        post_request.()
        expect( response ).to be_success
        expect( JSON.parse(response.body) ).to eq({'id' => NetexImport.last.id, 'type' => 'NetexImport'})
      end

      it 'creates a NetexImport object in the DB' do
        expect(&post_request).to change{NetexImport.count}.by(1)
      end
    end

    context 'with incorrect credentials and correct request' do
      let( :authorization ){ authorization_token_header( "#{referential.id}-incorrect_token") }

      it 'succeeds not' do
        post_request.()
        expect( response.status ).to eq(401)
      end

      it 'does not create an Import object' do
        expect(&post_request).not_to change{Import.count}
      end
    end

    context 'with correct credentials and incorrect request' do
      let( :authorization ){ authorization_token_header( get_api_key.token ) }
      let( :attributes ){ {
        netex_import: {
          referential_id: referential.id}
      } }

      it 'succeeds not' do
        post_request.()
        expect( response.status ).to eq(406)
        expect( json_response_body['errors']['file'] ).not_to be_empty
      end

      it 'does not create an Import object' do
        expect(&post_request).not_to change{Import.count}
      end
    end
  end
end
