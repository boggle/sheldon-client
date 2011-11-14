# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sheldon-client"
  s.version = "1.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pontus Lindstrom", "Benjamin Krause"]
  s.date = "2011-11-14"
  s.description = "The gem makes it possible to talk to sheldon using easy calls"
  s.email = "core@moviepilot.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    "lib/sheldon-client.rb",
    "lib/sheldon-client/configuration.rb",
    "lib/sheldon-client/crud/batch.rb",
    "lib/sheldon-client/crud/create.rb",
    "lib/sheldon-client/crud/crud.rb",
    "lib/sheldon-client/crud/delete.rb",
    "lib/sheldon-client/crud/read.rb",
    "lib/sheldon-client/crud/search.rb",
    "lib/sheldon-client/crud/update.rb",
    "lib/sheldon-client/http/exceptions.rb",
    "lib/sheldon-client/http/http.rb",
    "lib/sheldon-client/http/url_helper.rb",
    "lib/sheldon-client/sheldon/connection.rb",
    "lib/sheldon-client/sheldon/node.rb",
    "lib/sheldon-client/sheldon/questionnaire.rb",
    "lib/sheldon-client/sheldon/schema.rb",
    "lib/sheldon-client/sheldon/sheldon_object.rb",
    "lib/sheldon-client/sheldon/statistics.rb",
    "lib/sheldon-client/sheldon/status.rb",
    "lib/sheldon-client/sheldon/traverse.rb"
  ]
  s.homepage = "http://github.com/gozmo/sheldon-client"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.11"
  s.summary = "Talks to Sheldon"
  s.test_files = [
    "spec/client/exceptions_spec.rb",
    "spec/client/url_helper_spec.rb",
    "spec/requests/sheldon_client_requests_spec.rb",
    "spec/sheldon-client_spec.rb",
    "spec/sheldon/node_spec.rb",
    "spec/sheldon/schema_spec.rb",
    "spec/sheldon/statistics_spec.rb",
    "spec/sheldon/traverse_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/http_support.rb",
    "spec/support/web_mock_support.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<addressable>, ["~> 2.2.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_runtime_dependency(%q<elastodon>, ["~> 0.0.14"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<webmock>, ["~> 1.6"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<mp-deployment>, [">= 0"])
    else
      s.add_dependency(%q<addressable>, ["~> 2.2.0"])
      s.add_dependency(%q<activesupport>, [">= 3.0.0"])
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<elastodon>, ["~> 0.0.14"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<webmock>, ["~> 1.6"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<mp-deployment>, [">= 0"])
    end
  else
    s.add_dependency(%q<addressable>, ["~> 2.2.0"])
    s.add_dependency(%q<activesupport>, [">= 3.0.0"])
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<elastodon>, ["~> 0.0.14"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<webmock>, ["~> 1.6"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<mp-deployment>, [">= 0"])
  end
end

