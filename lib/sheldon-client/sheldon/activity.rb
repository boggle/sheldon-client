module SheldonClient

  class Activity

    attr_accessor :object, :created_at, :reason, :friend

    def initialize(data_hash)
      data_hash.symbolize_keys!
      @object     = SheldonClient::Node.new(data_hash[:content])
      @created_at = data_hash[:date]
      @reason     = data_hash[:reason]
      @friend     = data_hash[:friend]
    end
  end

  class Activities

    attr_accessor :activities

    def initialize(data_hash)
      @activities = []
      data_hash.each do |activity|
        @activities << SheldonClient::Activity.new(activity)
      end
    end
  end
end
