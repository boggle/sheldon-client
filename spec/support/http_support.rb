module HttpSupport
  include SheldonClient::UrlHelper

  # Helper function which returns options for the http request with a default
  # header and a given body.
  #
  # ==== Parameters
  # * <tt> body    </tt> Body of the http request
  # * <tt> options </tt> Optional Hash in case you want overwrite the headers
  #
  # ==== Examples
  #
  # => with_options({:weight => 1.0 }.to_json)
  # => { :headers => { "Accept"=>"application/json",
  #                    "Content-Type"=>"application/json"},
  #      :body    => "{\"weight\":1.0}" }
  #
  # => with_options({:weight => 0.4 }.to_json,
  #                 { :headers => { "Accept"=>"application/xml",
  #                                "Content-Type"=>"application/xml"}})
  # => {:headers => {"Accept"=>"application/xml", "Content-Type"=>"application/xml"},
  #     :body    => "{\"weight\":0.4}"}
  #
  def with_options( body, options = {} )
    default_headers =  { 'Accept'      => 'application/json',
                         'Content-Type'=> 'application/json',
                         'User-Agent'  => 'Ruby' }

    with =  { headers: default_headers }
    with[:body] = body
    with.merge!(options) unless options.empty?
    with
  end


  def request_data( body = nil, additional_headers = {} )
    default_headers =  { 'Accept'       => 'application/json',
                         'Content-Type' =>'application/json' }

    with = { headers: default_headers.update(additional_headers) }
    with[:body] = body.to_json if body
    with
  end


  def response( type, opts = {} )
    case type
      when :success             then { status: 200 }
      when :bad_request         then { status: 400 }
      when :not_found           then { status: 404 }
      when :node                then { status: 200, body: node_body(opts).to_json }
      when :node_collection     then { status: 200, body: [node_body(opts)].to_json }
      when :node_created        then { status: 201, body: node_body(opts).to_json }
      when :connection          then { status: 200, body: connection_body.to_json }
      when :connection_created  then { status: 200, body: connection_body.to_json }
      when :connection_collection then { status: 200, body: [connection_body].to_json }
      when :neighbour_collection then
       { status: 200,
         body: [{ type: neighbour_type.to_s.camelcase,
                  id: neighbour_id.to_s,
                  payload: neighbour_payload }].to_json }
    end
  end

  private

  def node_body(opts = {})
    { type: (opts[:node_type] || node_type).to_s.camelcase,
      id: opts[:node_id] || node_id,
      payload: opts[:payload] || payload }
  end

  def connection_body
    { type: connection_type.to_s.camelcase,
      from: from_id.to_s,
      to: to_id.to_s,
      payload: connection_payload }
  end
end
