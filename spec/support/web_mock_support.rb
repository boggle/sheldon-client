module WebMockSupport
  def stub_and_expect_request(method, url, with_options, result,  &block)
    stub_request(method, url).with(with_options).to_return(result)
    yield
    a_request(method, url).with(with_options).should have_been_made
  end


  def sheldon_status
    { "schema" => { "nodes"       => { "movies"  => { "properties" => [ "name" => [ 'exact' ] ],
                                                      "count"      => 4  },
                                       "persons" => { "properties" => [],
                                                      "count"      => 6  }},
                    "connections" => { "likes"  => { "properties" => [],
                                                     "sources"    => [ 'users' ],
                                                     "targets"    => [ 'movies', 'persons' ],
                                                     "count"      => 3 },
                                       "actors" => { "properties" => [],
                                                     "sources"    => [ 'movies' ],
                                                     "targets"    => [ 'persons' ],
                                                     "count"      => 2 },
                                       "g_tags" => { "properties" => [],
                                                     "sources"    => [ 'movies' ],
                                                     "targets"    => [ 'genres' ],
                                                     "count"      => 2 }}}
    }
  end

end
