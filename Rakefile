require 'echoe'
Echoe.new('logworm_amqp', '0.9.2') do |p|
  p.description = "logworm - logging service"
  p.url = "http://www.logworm.com"
  p.author = "Pomelo, LLC"
  p.email  = "schapira@pomelollc.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.development_dependencies = ["json >=1.4.3", "minion >=0.1.15", "ruby-hmac", "hpricot", "oauth", "heroku"]
  p.runtime_dependencies = ["json >=1.4.3", "minion >=0.1.15", "ruby-hmac", "memcache-client", "hpricot", "oauth", "heroku"]
end
