class SheldonClient
  class Questionnaire < Node
    attr_reader :answerers, :replies
    def initialize(data_hash)
      super
      @replies = parse_replies(data_hash[:replies])
      @answerers = data_hash[:answerers] || {}
    end

    private

    def parse_replies(replies = {})
      if not replies.empty?
        replies.each do |key,value|
          replies[key] = SheldonClient::Node.new(value)
        end
      else
        {}
      end
    end
  end
end
