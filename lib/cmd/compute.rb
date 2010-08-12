class LogwormCompute
    def initialize(table, function, field, options)
      @table    = table
      @function = function
      @field    = field
      @options  = options

      @valuefield = @field ? "#{@function}(#{@field})" : @function

      begin
        @db    = Logworm::DB.from_config_or_die(@options[:app])
        spec   = {:aggregate_function => @function, :aggregate_argument => @field}.merge(@options)
        @query = Logworm::QueryBuilder.new(spec)
      rescue Exception => e
        $stderr.puts "There was an error: #{e}"
        exit(-1)
      end
      
    end

    def run
      # Create a resource for the query
      begin
        query_data = @db.query(@table, @query.to_json)
        url = query_data["results_uri"]
        rows = @db.results(url + "?nocache=1")["results"]
      rescue Logworm::DatabaseException, Logworm::ForbiddenAccessException  => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      rescue Logworm::InvalidQueryException => e
        $stderr.puts "#{e}, #{@query.to_json}"  
        exit(-1)
      rescue Exception  => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      end

      if @options[:debug]
        puts "logworm query: #{@query.to_json}"
        puts "logworm query url: #{query_data["self_uri"]}"
        puts "logworm results url: #{url}"
        puts
      end
        
      if @query.groups.length > 0
        results = {}
        rows.each do |r|
          grp = []
          @query.groups.each do |g|
            grp << "#{g}:#{r[g]}"
          end
          key = "[#{grp.join(', ')}]"
          value = r[@function]
          results[key] = {:value => value, :keys => r.dup}
          results[key][:keys].delete(@function)
        end
        results.keys.sort.each do |k|
          puts "#{k} \t ==> #{@valuefield} = #{results[k][:value]}"
        end
      else
        puts "#{@valuefield} = #{rows.first[@function]}"
      end
      
    end

end