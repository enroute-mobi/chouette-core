module HttpService extend self

  Timeout = Faraday::TimeoutError

  def get_resource(host:, path:, token: nil, params: {})
    Faraday.new(url: host) do |c|
      c.headers['Authorization'] = "Token token=#{token.inspect}" if token
      c.adapter Faraday.default_adapter

      return c.get path, params
    end
  end

  def get_json_resource(host:, path:, token: nil, params: {})
    # Stupid Ruby!!! (I mean I just **need** Pattern Matching, maybe I need to write it myself :O)
    resp = get_resource(host: host, path: path, token: token, params: params) 
    if resp.status == 200
      return JSON.parse(resp.body)
    else
      raise "Error on api request status : #{resp.status} => #{resp.body}"
    end
  end
  # host: 'http://localhost:3000',
  # path: '/api/v1/netex_imports.json',
  # token: '13-74009c36638f587c9eafb1ce46e95585',
  # params: { netex_import: {referential_id: 13, workbench_id: 1}},
  # upload: {file: [StringIO.new('howdy'), 'application/zip', 'greeting']})
  def post_resource(host:, path:, token: nil, params: {}, upload: nil)
    Faraday.new(url: host) do |c|
      c.headers['Authorization'] = "Token token=#{token.inspect}" if token
      c.request :multipart
      c.request :url_encoded
      c.adapter Faraday.default_adapter
      return c.post path, params
    end
  end

  # Expose this in order to make the service replaceable
  def upload(*triple)
    Faraday::UploadIO.new(*triple)
  end
end
