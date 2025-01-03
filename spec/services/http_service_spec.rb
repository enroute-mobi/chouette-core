RSpec.describe HttpService do

  subject{ described_class }

  %i{host params path result}.each do |param|
    let(param){ double(param) }
  end
  let( :token ){ SecureRandom.hex }

  let( :faraday_connection ){ double('faraday_connection') }
  let( :headers ){ {} }


  context 'get_resource' do
    let( :params ){ double('params') }

    it 'sets authorization and returns result' do
      expect(Faraday).to receive(:new).with(url: host).and_yield(faraday_connection)
      expect(faraday_connection).to receive(:adapter).with(Faraday.default_adapter)
      expect(faraday_connection).to receive(:headers).and_return headers
      expect(faraday_connection).to receive(:get).with(path, params).and_return(result)

      expect(subject.get_resource(host: host, path: path, token: token, params: params)).to eq(result)
      expect(headers['Authorization']).to eq( "Token token=#{token.inspect}" )
    end
  end

  context 'post_resource' do
    %i{as_name  mime_type name upload_io value}.each do | param |
      let( param ){ double(param) }
    end

    let( :upload_list ){ [value, mime_type, as_name] }

    it 'sets authorization and posts data' do
      expect(Faraday).to receive(:new).with(url: host).and_yield(faraday_connection)
      expect(faraday_connection).to receive(:adapter).with(Faraday.default_adapter)
      expect(faraday_connection).to receive(:headers).and_return headers
      expect(faraday_connection).to receive(:request).with(:multipart)
      expect(faraday_connection).to receive(:request).with(:url_encoded)

      expect(faraday_connection).to receive(:post).with(path, params).and_return(result)

      expect(subject.post_resource(
        host: host,
        path: path,
        token: token,
        params: params,
        upload: {name => upload_list} )).to eq(result)
      expect(headers['Authorization']).to eq( "Token token=#{token.inspect}" )
    end

  end

  context 'get_json_resource' do

    let( :content ){ SecureRandom.hex }

    it 'delegates an parses the response' do
      expect_it.to receive(:get_resource)
        .with(host: host, path: path, token: token, params: params)
        .and_return(double(body: {content: content}.to_json, status: 200))

      expect( subject.get_json_resource(
        host: host,
        path: path,
        token: token,
        params: params) ).to eq('content' => content)
    end
  end
end
