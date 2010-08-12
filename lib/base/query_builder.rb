require 'rubygems'
require 'json'

###
# Receives a hash with options, and provides a to_json method that returns the query ready to be sent to the logworm server
# Switches (all optional)
#   :fields             => String with a comma-separated list of fields (quoted or not), or Array of Strings
#   :force_ts           => Boolean, specifies whether _ts should be added to the list of fields
#   :aggregate_function => String
#   :aggregate_argument => String
#   :aggregate_group    => String with a comma-separated list of fields (quoted or not), or Array of Strings
#   :conditions         => String with comma-separated conditions (in MongoDB syntax), or Array of Strings
#   :start              => String or Integer (for year)
#   :end                => String or Integer (for year)
#   :limit              => String or Integer
###
module Logworm
  class QueryBuilder
    
    attr_accessor :fields, :groups, :aggregate, :conditions, :tf, :limit
    
    def initialize(options = {})
      @options = options
      @options.merge(:force_ts => true) unless @options.include? :force_ts
      @query = build()
    end
  
    def to_json
      @query
    end
  
    private
    def build()
      query_opts = []
    
      ###
      # Fields : Array, or Comma-separated string
      ###
      @fields = to_array(@options[:fields])
      query_opts << '"fields":' + (@options[:force_ts] ? @fields + ["_ts"] : @fields).to_json if @fields.size > 0

      ###
      # Aggregate
      #  aggregate_function: String
      #  aggregate_argument: String (or empty)
      #  aggregate_group: String or Array
      ###
      @groups = to_array(@options[:aggregate_group])
      @aggregate = {}
      @aggregate[:function] = @options[:aggregate_function] if is_set?(@options[:aggregate_function])
      @aggregate[:argument] = @options[:aggregate_argument] if is_set?(@options[:aggregate_argument])
      @aggregate[:group_by] = groups[0] if groups.size == 1
      @aggregate[:group_by] = groups if groups.size > 1
      query_opts << '"aggregate":' + @aggregate.to_json if @aggregate.keys.size > 0
    
      if @fields.size > 0 and @aggregate.keys.size > 0
        raise Logworm::InvalidQueryException.new("Queries cannot contain both fields and aggregates") 
      end
    
      ###
      # Conditions : Array, or Comma-separated string
      # ['"a":10' , '"b":20']
      # "a:10", "b":20
      ###
      @conditions = to_string(@options[:conditions])
      query_opts << '"conditions":{' + conditions + "}" if conditions.size > 0

      ###
      # Timeframe: String
      ###
      @tf = {}
      @tf[:start] = unquote(@options[:start]).to_s if is_set?(@options[:start]) or is_set?(@options[:start], Integer, 0)
      @tf[:start] = unquote(@options[:start].strftime("%Y-%m-%dT%H:%M:%SZ")).to_s if is_set?(@options[:start], Time)
      @tf[:end]   = unquote(@options[:end]).to_s if is_set?(@options[:end]) or is_set?(@options[:end], Integer, 0)
      @tf[:end]   = unquote(@options[:end].strftime("%Y-%m-%dT%H:%M:%SZ")).to_s if is_set?(@options[:end], Time)
      query_opts << '"timeframe":' + @tf.to_json if @tf.keys.size > 0

      ###
      # Limit
      # String or Integer
      ###
      if (is_set?(@options[:limit], Integer, 200) or is_set?(@options[:limit], String, ""))
        @limit = @options[:limit].to_s
        query_opts << '"limit":' + @limit
      end

      # And the string
      "{#{query_opts.join(", ")}}"
    end
  
    def to_array(arg)
      return [] if arg.nil?
      return arg if arg.is_a? Array
      return arg.split(",").map {|e| unquote(e.strip)} if arg.is_a? String and arg.split != ""
      []
    end

    def to_string(arg)
      return "" if arg.nil?
      return arg.split(",").map {|e| e.strip}.join(",") if arg.is_a? String
      return arg.join(",") if arg.is_a? Array and arg.size > 0
      ""
    end
  
    def unquote(str)
      return str unless str.is_a? String
      str.gsub(/^"/, '').gsub(/"$/,'')
    end

    def is_set?(elt, klass = String, empty_val = "")
      elt and elt.is_a?(klass) and elt != empty_val
    end
  
  end
end