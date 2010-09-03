require File.dirname(__FILE__) + '/base/db'
require File.dirname(__FILE__) + '/base/config'
require File.dirname(__FILE__) + '/base/query_builder'

require File.dirname(__FILE__) + '/client/logger'
require File.dirname(__FILE__) + '/client/rack'
require File.dirname(__FILE__) + '/client/rails'

def lw_log (logname, values)
  Logworm::Logger.log(logname, values)
end
alias :log_in :lw_log

def lw_with_log(values)
  Logworm::Logger.attach_to_log(:web_log, values)
end
alias :log_with_request :lw_with_log

###
# Perform a query against the logworm server
# 
# Requires a log table, and a query
# The query can be provided as a JSON string, following the syntax described in http://www.logworm.com/docs/query
#  or as a Hash of options, with the following keys (all optional)
#   :fields             => String with a comma-separated list of fields (quoted or not), or Array of Strings
#   :aggregate_function => String
#   :aggregate_argument => String
#   :aggregate_group    => String with a comma-separated list of fields (quoted or not), or Array of Strings
#   :conditions         => String with comma-separated conditions (in MongoDB syntax), or Array of Strings
#   :start              => String or Integer (for year)
#   :end                => String or Integer (for year)
#   :limit              => String or Integer
# 
# See Logworm::QueryBuilder
# 
# Returns Hash with
#  id              ==> id of the query
#  query_url       ==> URL to GET information about the query
#  results_url     ==> URL to GET the results for the query
#  created         ==> First creation of the query
#  updated         ==> most recent update of the query and/or its results
#  expires         ==> until that datime, the query won't be rerun against the database
#  execution_time  ==> time in ms to run the query
#  results         ==> array of hashmaps. Each element corresponds to a log entry, with its fields
#
# raises Logworm::DatabaseException, Logworm::ForbiddenAccessException, Logworm::InvalidQueryException
# or just a regular Exception if it cannot find the URL to the logging database
###
def lw_query(logname, query = {}, ttl = nil) 
  db = Logworm::DB.from_config_or_die                                   # Establish connection to DB
  query = Logworm::QueryBuilder.new(query).to_json if query.is_a? Hash  # Turn query into proper JSON string
  query_data = db.query(logname, query, ttl)                            # POST to create query
  db.results(query_data["results_uri"])                                 # GET from query's results uri
end

###
# Returns an array with information about the logging tables in the database
# Each element in the array has;
#  :tablename   => The name of the logging table
#  :url         => The URL for POSTing new log entries
#  :last_write  => Datetime of last entry
#  :rows        => Count of entries
#
# raises Logworm::DatabaseException, Logworm::ForbiddenAccessException, Logworm::InvalidQueryException
# or just a regular Exception if it cannot find the URL to the logging database
###
def lw_list_logs
  db = Logworm::DB.from_config_or_die                                   # Establish connection to DB
  db.tables                                                             # Call tables command
end
