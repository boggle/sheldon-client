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
                         'Content-Type' =>'application/json',
                         'User-Agent'   => 'Ruby' }

    with = { headers: default_headers.update(additional_headers) }
    with[:body] = body.to_json if body
    with
  end


  def response( type, opts = {} )
    case type
      when :bad_request           then { status: 400, body: [].to_json }
      when :connection            then { status: 200,
                                         body: connection_body(opts).to_json   }
      when :connection_collection then { status: 200,
                                         body: [connection_body(opts)].to_json }
      when :connection_created    then { status: 200,
                                         body: connection_body(opts).to_json   }
      when :empty_collection      then { status: 200, body: [].to_json                }
      when :node                  then { status: 200, body: node_body(opts).to_json   }
      when :node_collection       then { status: 200, body: [node_body(opts)].to_json }
      when :node_created          then { status: 201, body: node_body(opts).to_json   }
      when :not_found             then { status: 404 }
      when :success               then { status: 200, body: {}.to_json}
      when :statistics            then { status: 200, body: statistics_body.to_json }
      when :status                then { status: 200, body: sheldon_status.to_json }
      when :container_pagerank    then { status: 200, body: pagerank_body.to_json }
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

  def connection_body(opts = {})
    { id: opts[:connection_id] || connection_id,
      type: (opts[:connection_type] || connection_type).to_s.camelcase,
      from: (opts[:from_id] || from_id).to_s,
      to: (opts[:to_id] || to_id).to_s,
      payload: opts[:payload] || connection_payload }
  end

  def statistics_body
    { "nodes"=> { "movies" => { "count"=>49467 },
                  "series"=>{"count"=>1516 } },
      "connections" => { "actings"    => {"count"=> 4667 },
                         "directings" => { "count" => 455 },
                         "genre_taggings" => { "count" => 953 }}
    }
  end

  def pagerank_body
    [
      {
      "node" => {
      "payload" => {
      "published_at" => "2011-07-29T14:08:04+02:00",
      "created_at" => "2011-07-29T14:15:48+02:00",
      "updated_at" => "2011-09-07T10:39:12+02:00",
      "title" => "Judge: Marvel Owns Rights to 'Fantastic Four,' 'Spider-Man,' 'X-Men,' 'Iron Man' and 'Incredible Hulk'",
      "edward_id" => 2326
    },
      "type" => "Container",
      "id" => "212541"
    },
      "rank" => 10
    },
      {
      "node" => {
      "payload" => {
      "published_at" => "2011-07-29T12:45:50+02:00",
      "created_at" => "2011-07-29T12:50:54+02:00",
      "updated_at" => "2011-09-07T10:31:46+02:00",
      "title" => "'The Dark Knight Rises' in Pittsburgh",
      "edward_id" => 2298
    },
      "type" => "Container",
      "id" => "212510"
    },
      "rank" => 7
    }]
  end
end
