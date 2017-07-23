class HTTPService
  def self.get_resource(*args)
    new.get_resource(*args)
  end

  def get_resource(host:, path:, token: nil, params: {}, parse_json: false) 
    Faraday.new(url: host) do |c|
      c.headers['Authorization'] = "Token token=#{token.inspect}" if token
      c.adapter Faraday.default_adapter

      resp = c.get path, params
      if resp.status == 200
        return parse_json ? JSON.parse(resp.body) : resp.body
      else
        raise "Error on api request status : #{resp.status} => #{resp.body}"
      end
    end
  end

  def post_resource(host:, path:, resource_name:, token: nil, params: {}, upload: nil)
    Faraday.new(url: host) do |c|
      c.headers['Authorization'] = "Token token=#{token.inspect}" if token
      c.request :multipart
      c.request :url_encoded
      c.adapter Faraday.default_adapter

      if upload
        name = upload.keys.first
        value, mime_type, as_name = upload.values.first
        params.update( name => Faraday::UploadIO.new(value, mime_type, as_name ) )
      end

      c.post path, resource_name => params
    end
  end
end
