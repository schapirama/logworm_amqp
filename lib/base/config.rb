require 'singleton'

module Logworm
  class ConfigFileNotFound < Exception ; end
  
  class Config
    
    include ::Singleton
      
    FILENAME = ".logworm"
    
    def initialize
      reset
    end
    
    def reset
      @file_found = false
      @url = nil
    end
    
    def read
      begin
        f = File.new("./" + FILENAME, 'r')
        @url = f.readline.strip
        @file_found = true
      rescue Errno::ENOENT => e
      end
      self
    end

    def url
      @url
    end
    
    def file_found?
      @file_found and (!@url.nil? and @url != "")
    end
    
    def save(url)
      File.open("./" + FILENAME, 'w') do |f|
        f.puts url
      end rescue Exception
      %x[echo #{FILENAME} >> .gitignore]
    end
    
  end

end

