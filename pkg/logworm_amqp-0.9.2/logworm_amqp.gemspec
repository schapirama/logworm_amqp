# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{logworm_amqp}
  s.version = "0.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pomelo, LLC"]
  s.date = %q{2010-08-11}
  s.description = %q{logworm - logging service}
  s.email = %q{schapira@pomelollc.com}
  s.executables = ["lw-compute", "lw-tail"]
  s.extra_rdoc_files = ["CHANGELOG", "bin/lw-compute", "bin/lw-tail", "lib/base/config.rb", "lib/base/db.rb", "lib/base/query_builder.rb", "lib/client/logger.rb", "lib/client/rack.rb", "lib/client/rails.rb", "lib/cmd/compute.rb", "lib/cmd/tail.rb", "lib/logworm_amqp.rb", "lib/logworm_utils.rb"]
  s.files = ["CHANGELOG", "Manifest", "Rakefile", "bin/lw-compute", "bin/lw-tail", "lib/base/config.rb", "lib/base/db.rb", "lib/base/query_builder.rb", "lib/client/logger.rb", "lib/client/rack.rb", "lib/client/rails.rb", "lib/cmd/compute.rb", "lib/cmd/tail.rb", "lib/logworm_amqp.rb", "lib/logworm_utils.rb", "logworm_amqp.gemspec"]
  s.homepage = %q{http://www.logworm.com}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Logworm_amqp"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{logworm_amqp}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{logworm - logging service}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 1.4.3"])
      s.add_runtime_dependency(%q<minion>, [">= 0.1.15"])
      s.add_runtime_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_runtime_dependency(%q<memcache-client>, [">= 0"])
      s.add_runtime_dependency(%q<hpricot>, [">= 0"])
      s.add_runtime_dependency(%q<oauth>, [">= 0"])
      s.add_runtime_dependency(%q<heroku>, [">= 0"])
      s.add_development_dependency(%q<json>, [">= 1.4.3"])
      s.add_development_dependency(%q<minion>, [">= 0.1.15"])
      s.add_development_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_development_dependency(%q<hpricot>, [">= 0"])
      s.add_development_dependency(%q<oauth>, [">= 0"])
      s.add_development_dependency(%q<heroku>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 1.4.3"])
      s.add_dependency(%q<minion>, [">= 0.1.15"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<memcache-client>, [">= 0"])
      s.add_dependency(%q<hpricot>, [">= 0"])
      s.add_dependency(%q<oauth>, [">= 0"])
      s.add_dependency(%q<heroku>, [">= 0"])
      s.add_dependency(%q<json>, [">= 1.4.3"])
      s.add_dependency(%q<minion>, [">= 0.1.15"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<hpricot>, [">= 0"])
      s.add_dependency(%q<oauth>, [">= 0"])
      s.add_dependency(%q<heroku>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 1.4.3"])
    s.add_dependency(%q<minion>, [">= 0.1.15"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<memcache-client>, [">= 0"])
    s.add_dependency(%q<hpricot>, [">= 0"])
    s.add_dependency(%q<oauth>, [">= 0"])
    s.add_dependency(%q<heroku>, [">= 0"])
    s.add_dependency(%q<json>, [">= 1.4.3"])
    s.add_dependency(%q<minion>, [">= 0.1.15"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<hpricot>, [">= 0"])
    s.add_dependency(%q<oauth>, [">= 0"])
    s.add_dependency(%q<heroku>, [">= 0"])
  end
end
