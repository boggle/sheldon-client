class SheldonClient
  module Configuration
    def host
      temp_host || @host || "http://46.4.114.22:2311"
    end

    def host=( value )
      @host = value.chomp("/")
    end

    def temp_host=( value )
      value = value.chomp("/") if value.is_a?(String)
      Thread.current['SheldonClient.host'] = value
    end

    def temp_host
      Thread.current['SheldonClient.host']
    end

    def log?
      @log || false
    end

    def log=( value )
      @log = value
    end

    def log_file=( value )
      @logfile = value
    end

    def log_file
      @logfile
    end
  end
end
