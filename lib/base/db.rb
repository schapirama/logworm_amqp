require 'oauth'
require 'json'
require 'minion'
require 'hmac-sha1'
require 'cgi'
require 'base64'


module Logworm
  class ForbiddenAccessException < Exception ; end
  class DatabaseException < Exception ; end
  class InvalidQueryException < Exception ; end

  include Minion
  Minion::logger do |msg|
  end
  
  class DB
    
    URL_FORMAT    = /logworm:\/\/([^:]+):([^@]+)@([^\/]+)\/([^\/]+)\/([^\/]+)\//
    # URI: logworm://<consumer_key>:<consumer_secret>@db.logworm.com/<access_token>/<access_token_secret>/

    MIN_AQMP         = 500
    STATS_FREQ       = 300
    RETRY_FREQUENCY  = 60
 
    attr_reader :host, :consumer_key, :consumer_secret, :token, :token_secret
      

    def initialize(url)
      match = DB.parse_url(url)
      raise ForbiddenAccessException.new("Incorrect URL Format #{url}") unless match and match.size == 6      
      @consumer_key, @consumer_secret, @host, @token, @token_secret = match[1..5]
      @connection = OAuth::AccessToken.new(OAuth::Consumer.new(@consumer_key, @consumer_secret), @token, @token_secret)
    end
  
    def self.with_tokens(token, token_secret)
      consumer_key    = ENV["#{ENV['APP_ID']}_APPS_KEY"]
      consumer_secret = ENV["#{ENV['APP_ID']}_APPS_SECRET"]
      host            = ENV["#{ENV['APP_ID']}_DB_HOST"]
      DB.new(DB.make_url(host, consumer_key, consumer_secret, token, token_secret))
    end
    
    def self.from_config(app = nil)
      # Try with URL from the environment. This will certainly be the case when running on Heroku, in production.
      return DB.new(ENV['LOGWORM_URL']) if ENV['LOGWORM_URL'] and DB.parse_url(ENV['LOGWORM_URL'])
      
      # If no env. found, try with configuration file, unless app specified
      config = Logworm::Config.instance
      config.read
      unless app
        return DB.new(config.url) if config.file_found? and DB.parse_url(config.url)
      end

      # Try with Heroku configuration otherwise
      cmd = "heroku config --long #{app ? " --app #{app}" : ""}"
      config_vars = %x[#{cmd}] || ""
      m = config_vars.match(Regexp.new("LOGWORM_URL\\s+=>\\s+([^\\n]+)"))
      if m and DB.parse_url(m[1])
        config.save(m[1]) unless (config.file_found? and app) # Do not overwrite if --app is provided
        return DB.new(m[1])
      end
      
      nil
    end
    
    def self.from_config_or_die(app = nil)
      db = self.from_config(app)
      raise "The application is not properly configured. Either use 'heroku addon:add' to add logworm to your app, or save your project's credentials into the .logworm file" unless db
      db
    end

    def self.make_url(host, consumer_key, consumer_secret, token, token_secret)
      "logworm://#{consumer_key}:#{consumer_secret}@#{host}/#{token}/#{token_secret}/"
    end

    def url()
      DB.make_url(@host, @consumer_key, @consumer_secret, @token, @token_secret)
    end
    
    def self.example_url()
      self.make_url("db.logworm.com", "Ub5sOstT9w", "GZi0HciTVcoFHEoIZ7", "OzO71hEvWYDmncbf3C", "J7wq4X06MihhZgqDeB")
    end

    
    def tables()
      db_call(:get, "#{host_with_protocol}/") || []
    end
  
    def query(table, cond)
      db_call(:post, "#{host_with_protocol}/queries", {:table => table, :query => cond})
    end
    
    
  
    def results(uri)
      res = db_call(:get, uri)
      raise InvalidQueryException.new("#{res['error']}") if res['error']
      res["results"] = JSON.parse(res["results"])
      res
    end
    
    def signature(base_string, consumer_secret) 
      secret="#{escape(consumer_secret)}&" 
      Base64.encode64(HMAC::SHA1.digest(secret,base_string)).chomp.gsub(/\n/,'') 
    end 

    def escape(value) 
      CGI.escape(value.to_s).gsub("%7E", '~').gsub("+", "%20") 
    end 
        
    def get_amqp_url()
      if @amqp_url.nil? and (@last_attempt.nil? or (Time.now - @last_attempt) > RETRY_FREQUENCY)
        begin
          resp = db_call(:get, "#{host_with_protocol}/amqp_url")
          @amqp_url = resp["url"]
          @stats_freq = resp["stats_freq"]
          @amqp_prefix = resp["prefix"] || "lw"
          $stderr.puts "logworm server acquired: #{@amqp_url.gsub(/[^@]+@/, "amqp://")}"
          Minion.amqp_url = @amqp_url
          reset_stats
        rescue Exception => e
          @last_attempt = Time.now
          $stderr.puts "logworm cannot connect to server; waiting #{RETRY_FREQUENCY} seconds before retry. log entries will be lost"
        end
      end
      !(@amqp_url.nil?)
    end
        
    def to_amqp(queue, payload)
       if get_amqp_url
         content = payload.to_json
         sig= signature(content, @token_secret )
         Minion.enqueue("#{@amqp_prefix}.#{queue}", {:payload => content, :consumer_key => @token, :signature => sig, 
                                :env => ENV['RACK_ENV'] || "?"})
       end
    end
  
    def recording_stats()
      s = Time.now
      yield if block_given?
      record_stats((Time.now - s))
      push_stats() if (rand(@stats_freq || 0) == 1)
    end 
    
    def record_stats(value)
      @tock += 1
      @total_time += value
      @amqp_max = value if value > @amqp_max
      @amqp_min = value if value < @amqp_min
    end

    def push_stats()
      avg = sprintf('%.6f', (@total_time / @tock)).to_f
      len = sprintf('%.2f', (Time.now - @sampling_start)).to_f
      to_amqp("stats", {:avg => avg , :max => @amqp_max, :min => @amqp_min, 
                           :total => @total_time, :count => @tock, :sampling_length => len})
      $stderr.puts "logworm statistics: #{@tock} messages sent in last #{len} secs. Times: #{avg * 1000}/#{@amqp_min * 1000}/#{@amqp_max * 1000} (avg/min/max msecs)"
       reset_stats
    end
    
    def reset_stats()
      @total_time = @tock = @amqp_max = 0
      @amqp_min = MIN_AQMP
      @sampling_start = Time.now
    end
  
    def batch_log(entries)
      recording_stats do
        to_amqp("logging", {:entries => entries})
      end
    end

  private
    def db_call(method, uri, params = {})
      begin
        res = @connection.send(method, uri, params)
      rescue SocketError
        raise DatabaseException
      end
      raise InvalidQueryException.new("#{res.body}")              if res.code.to_i == 400
      raise ForbiddenAccessException                              if res.code.to_i == 403
      raise DatabaseException                                     if res.code.to_i == 404
      raise DatabaseException.new("Server returned: #{res.body}") if res.code.to_i == 500
      begin
        JSON.parse(res.body)
      rescue Exception => e
        raise DatabaseException.new("Database reponse cannot be parsed: #{e}")
      end
    end
    
    def self.parse_url(url)
       url.match(URL_FORMAT)
    end
    
    def host_with_protocol
      "http://#{@host}"
    end
  end

end

