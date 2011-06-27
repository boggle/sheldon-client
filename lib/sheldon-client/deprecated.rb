class SheldonClient
  module Deprecated
    # TODO: __DEPRECATED__
    def get_node_types
      warn 'SheldonClient#get_node_types is deprecated and will be removed from sheldon-client 0.3 - please use SheldonClient#node_types'
      node_types
    end

    # TODO: __DEPRECATED__
    def get_edge_types
      warn 'SheldonClient#get_node_types is deprecated and will be removed from sheldon-client 0.3 - please use SheldonClient#edge_types'
      edge_types
    end
  end
end