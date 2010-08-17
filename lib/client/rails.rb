###
# Extemds ActionController::Base and aliases the process method, to wrap it with the standard logworm request cycle
#
# By default it will automatically log web requests (in a short format) into web_log
# Can also log headers, if specified
###
if defined?(ActionController) and Rails::VERSION::STRING and Rails::VERSION::STRING < "3.0.0"

  require 'benchmark'

  ActionController::Base.class_eval do
    ## Basic settings: log requests, without headers. Use default db, and timeout after 1 second
    @@log_requests = true
    @@log_headers  = false
    @@dev_logging  = false
    @@timeout = 1
    Logworm::Logger.use_default_db
    
    ###
    # Disable automatic logging of requests
    # Use from ApplicationController
    ###
    def self.donot_log_requests
      @@log_requests = false
    end
    
    ###
    # Log headers with requests
    # Use from ApplicationController
    ###
    def self.log_headers
      @@log_headers = true
    end
    
    ###
    # Turn on logging in development mode
    ###
    def self.log_in_development
      @@dev_logging = true
    end
    
    ###
    # Replaces (and embeds) the default Rails processing of a request. 
    # Call the original method, logs the request unless disabled, and flushes the logworm list
    ###
    def process_with_logworm_log(request, response, method = :perform_action, *arguments)
      unless (RAILS_ENV == 'production' or (RAILS_ENV == 'development' and @@dev_logging))
        return process_without_logworm_log(request, response, method, *arguments) 
      end
      
      Logworm::Logger.start_cycle
      begin
        startTime = Time.now 
        response  = process_without_logworm_log(request, response, method, *arguments)
        appTime   = (Time.now - startTime) 
      ensure
        log_request(request, response, appTime)
        return response
      end
    end
    alias_method_chain :process, :logworm_log
    

    private
    def log_request(request, response, appTime)
      method       = request.env['REQUEST_METHOD']
      path         = request.env['REQUEST_PATH'].blank? ? "/" : request.env['REQUEST_PATH']
      ip           = request.env['REMOTE_ADDR']
      http_headers = request.headers.reject {|k,v| !(k.to_s =~ /^HTTP/) }
      status       = response.status[0..2]
      queue_size   = request.env['HTTP_X_HEROKU_QUEUE_DEPTH'].blank? ? -1 : request.env['HTTP_X_HEROKU_QUEUE_DEPTH'].to_i

      entry = { :summary         => "#{method} #{path} - #{status} #{appTime}", 
                :request_method  => method,
                :request_path    => path, 
                :request_ip      => ip,
                :input           => cleaned_input(request),
                :response_status => status, 
                :profiling       => appTime,
                :queue_size      => queue_size}
      entry[:request_headers] = http_headers if @@log_headers
      entry[:response_headers] = response.headers if @@log_headers
      Logworm::Logger.log(:web_log, entry) if @@log_requests

      begin 
        Timeout::timeout(@@timeout) { 
          Logworm::Logger.flush
        } 
      rescue Exception => e 
        # Ignore --nothing we can do. The list of logs may (and most likely will) be preserved for the next request
        Rails.logger.error("logworm call failed: #{e}")
      end
    end
    
    def cleaned_input(request)
      pars = request.parameters.clone
      pars.delete("controller")
      pars.delete("action")
      respond_to?(:filter_parameters) ? filter_parameters(pars) : pars
    end
    
  end

end

