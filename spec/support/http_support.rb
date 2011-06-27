module HttpSupport

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
    default_headers =  { 'Accept'=> 'application/json',
                        'Content-Type'=>'application/json' }

    with =  { headers: default_headers }
    with[:body] = body
    with.merge!(options) unless options.empty?
    with
  end
end
