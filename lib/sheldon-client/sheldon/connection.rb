class SheldonClient
  class Connection < SheldonObject
    attr_accessor :to_id, :from_id

    def initialize( data_hash )
      super
      self.to_id   = data_hash[:to].to_i
      self.from_id = data_hash[:from].to_i
    end

    def from
    end

    def to
      SheldonObject.node( to_id )
    end

    def from
      SheldonObject.node( from_id )
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
      "#<Sheldon::Connection #{id} (#{type}/#{from_id}->#{to_id})>"
    end
  end
end
