class SheldonClient
  class Edge
    attr_accessor :id, :type, :payload,:to,:from

    def initialize( hash )
      self.id      = hash['id']
      self.to      = hash['to']
      self.from    = hash['from']
      self.type    = hash['type']
      self.payload = hash['payload']
    end

    def <=>(edge)
      if edge.payload['weight'].to_f == payload['weight'].to_f
        0
      elsif edge.payload['weight'].to_f > payload['weight'].to_f
        1
      else
        -1
      end
    end

    def to_s
      "#<Sheldon::Edge #{id} (#{type}/#{from}->#{to})>"
    end
  end
end
