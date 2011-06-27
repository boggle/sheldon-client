module WebMockSupport
  def stub_and_expect_request(method, url, with_options, result,  &block)
    stub_request(method, url).with(with_options).to_return(result)
    yield
    a_request(method, url).with(with_options).should have_been_made
  end
end
