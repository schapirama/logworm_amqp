require 'json'
  
module Logworm
  class LogwormException < Exception ; end

  class Logger
    $lr_queue = []
    $attaches = {}
    
    ###
    # Use connection to the backend servers specified in environment variable or config file
    ###
    def self.use_default_db
       $lw_server = DB.from_config
    end
    
    ###
    # Use a connection to a manually specified server
    ###
    def self.use_db(db)
      $lw_server = db
    end
    
    ###
    # Returns a reference to the current backend server
    ###
    def self.db
      $lw_server
    end
    
    
    ###
    # Starts a new cycle: sets a request_id variable, so that all entries (until flush) share that id
    ###
    def self.start_cycle
      $request_id = "#{Thread.current.object_id}-#{(Time.now.utc.to_f * 1000).to_i}"
    end

    ###
    # Record an entry. Not sent to the servers until 'flush' is called
    #
    # Warning: may raise Exception if there's a problem. It's up to the called to rescue from it in order to continue the processing
    # of a web request, for example.
    ###
    def self.log(table, values = {})
      return unless table and (table.is_a? String or table.is_a? Symbol)
      return unless values.is_a? Hash

      # Turn keys into symbols, delete empty ones, rename conflicting ones
      kvalues = cleanup(values)
      
      # Add information
      ts = Time.now.utc
      kvalues[:_ts_utc]     = (ts.to_f * 1000).to_i
      kvalues[:_ts]         = ts.strftime("%Y-%m-%dT%H:%M:%SZ")
      kvalues[:_request_id] = $request_id if $request_id
      
      # Enqueue
      $lr_queue << [table, kvalues]
    end
    
    ###
    # Allows to add fields to ALL log entries that go to a particular table.
    # Can be used, for example, to add user-level and app-specific data to the :web_log log
    # Notice that it overwrites previously attached fields. For example
    #  attach_to_log(:xx, {:a = 1})
    #  attach_to_log(:xx, {:a = 2})
    # will end up attaching just :a => 2 to every :xx log
    ###
    def self.attach_to_log(table, values = {})
      $attaches[table] = ($attaches[table] ? $attaches[table].merge(values) : values)
    end

    ###
    # Sends the entries to the server, if configured
    # Returns the number of entries send, and the time it takes
    #
    # Warning: may raise Exception if there's a problem. It's up to the called to rescue from it in order to continue the processing
    # of a web request, for example.
    ###
    def self.flush
      to_send = $lr_queue.size

      # Return if no entries
      return [0,0] if to_send == 0 

      # Return if no server
      unless $lw_server
        $stderr.puts "\t logworm not configured. #{to_send} entries dropped."
        $lr_queue = [] 
        return [0,0]
      end
      
      # Apply a-posteriori attachments
      # It merges, and so that attachment may overwrite 
      $lr_queue.each do |le|
        le[1].merge!($attaches[le[0]]) if $attaches[le[0]]
      end
      
      startTime = Time.now
      $lw_server.batch_log($lr_queue.to_json)
      $lr_queue = [] 
      endTime = Time.now
      
      [to_send, (endTime - startTime)]
    end
    
    private
    # Turn keys into symbols, delete empty ones, rename conflicting ones
    def self.cleanup(values)
      kvalues = {}
      values.each {|k,v| kvalues[k.to_sym] = v unless k.to_s == ""}
      [:_ts, :_ts_utc, :_request_id].each do |k|
        kvalues["orig_#{k}".to_sym] = kvalues[k] if kvalues.has_key? k
      end
      kvalues
    end
  end
end