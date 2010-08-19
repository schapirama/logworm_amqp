require 'rack/request'

module Logworm
  class Rack

    def initialize(app, options = {})
      @app = app
      
      @log_requests = (options[:donot_log_requests].nil? or options[:donot_log_requests] != true)
      @log_headers  = (options[:log_headers] and options[:log_headers] == true)
      @dev_logging  = (options[:log_in_development] and options[:log_in_development] == true)
      Logger.use_default_db
      @timeout = (ENV['RACK_ENV'] == 'production' ? 1 : 5) 
    end

    def call(env)
      return @app.call(env) unless (ENV['RACK_ENV'] == 'production' or (ENV['RACK_ENV'] == 'development' and @dev_logging))

      Logger.start_cycle
      begin
        startTime = Time.now 
        status, response_headers, body = @app.call(env) 
        appTime = (Time.now - startTime) 
      ensure
        log_request(env, status, response_headers, appTime)
        return [status, response_headers, body] 
      end
    end
    
    private 
    def log_request(env, status, response_headers, appTime)
      method       = env['REQUEST_METHOD']
      path         = env['PATH_INFO'] || env['REQUEST_PATH'] || "/"
      ip           = env['REMOTE_ADDR']
      http_headers = env.reject {|k,v| !(k.to_s =~ /^HTTP/) }
      queue_size   = env['HTTP_X_HEROKU_QUEUE_DEPTH'].nil? ? -1 : env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_i

      entry = { :summary         => "#{method} #{path} - #{status} #{appTime}", 
                :request_method  => method,
                :request_path    => path, 
                :request_ip      => ip,
                :input           => ::Rack::Request.new(env).params,
                :response_status => status, 
                :profiling       => appTime,
                :queue_size      => queue_size}
      entry[:request_headers] = http_headers if @log_headers
      entry[:response_headers] = response_headers if @log_headers
      Logger.log(:web_log, entry) if @log_requests

      begin 
        Timeout::timeout(@timeout) { 
          Logger.flush
        } 
      rescue Exception => e 
        # Ignore --nothing we can do. The list of logs may (and most likely will) be preserved for the next request
        env['rack.errors'].puts("logworm call failed: #{e}")
      end
    end

  end
end
