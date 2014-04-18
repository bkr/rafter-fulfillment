module Fulfillment
  class ShipmentItem < ModelBase

    def initialize(client, data)
      @client = client
      make_getter_methods(data)
    end
  end
end