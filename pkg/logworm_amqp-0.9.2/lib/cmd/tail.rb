class LogwormTail
    def initialize(table, options)
      @table   = table
      @options = options

      begin
        @db    = Logworm::DB.from_config_or_die(@options[:app])
        @query = Logworm::QueryBuilder.new(@options.merge(:force_ts => true))
      rescue Exception => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      end
    end

    def self.list(options = {})
      begin
        @db    = Logworm::DB.from_config_or_die(options[:app])
        @tables = @db.tables
        if @tables and @tables.size > 0
          puts "The following are the tables that you've created thus far:"
          @tables.sort {|x,y| x["tablename"] <=> y["tablename"]}.each do |t| 
            puts "\t - #{t["tablename"]}, #{t["rows"]} rows, last updated on #{date_time(t["last_write"])}"
          end
        else
          puts "You haven't recorded any data yet."
        end
      rescue Exception => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      end
    end
    
    def run
      # Create a resource for the query
      begin
        query_data = @db.query(@table, @query.to_json)
        url = query_data["results_uri"]
      rescue Logworm::DatabaseException, Logworm::ForbiddenAccessException  => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      rescue Logworm::InvalidQueryException => e
        $stderr.puts "#{e}"  
        exit(-1)
      rescue Exception  => e
        $stderr.puts "Error: #{e}"
        exit(-1)
      end

      if @options[:debug]
        puts "logworm query: #{@query.to_json}"
        puts "logworm query url: #{query_data["self_uri"]}"
        puts "logworm results url: #{url}"
        puts "refresh frequency: #{@options[:frequency]}" if @options[:loop]
        puts
      end
  
      while true do
        begin
          last_printed = print_rows(@db.results(url + "?nocache=1")["results"], last_printed || nil)
        rescue Logworm::DatabaseException, Logworm::ForbiddenAccessException  => e
          $stderr.puts "Error: #{e}"
          exit(-1)
        rescue Logworm::InvalidQueryException => e
          $stderr.puts "#{e}"  
          exit(-1)
        rescue Exception  => e
          $stderr.puts "Error: #{e}"
          exit(-1)
        end
        exit(0) unless @options[:loop]
        sleep @options[:frequency]
      end
    end

  private

    def self.date_time(val)
      val.gsub(/T/, ' @ ').gsub(/Z/, ' GMT')
    end
    
    def print_rows(rows, last)
      last = "" if last.nil?
      rows.reverse.each do |r|
        next unless r["_ts"]
        if r["_ts"] > last
          last = r["_ts"]
          r.delete("_id") unless @options[:fields].include?("_id")
          r.delete("_ts") unless @options[:fields].include?("_ts")
          puts "#{LogwormTail.date_time(last)} ==> "
          print_row(r)
        end
      end
      last
    end

    def print_row(r)
      if @options[:flat]
        puts "\t" + r.keys.sort.map {|k| "#{k}: #{r[k].inspect}"}.join(', ')
      else
        r.keys.sort.each do |k|
          puts "\t#{k}: #{r[k].inspect}"
        end
        puts
      end
    end
end