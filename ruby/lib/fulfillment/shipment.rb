module Fulfillment
  class Shipment < ModelBase

    attr_accessor :client

    def initialize(client, data)
      @client = client
      make_getter_methods(data)
    end

    def shipment_items(first_page_num = 1)
      Fulfillment::Shipment.shipment_items(self.client, self.public_id, first_page_num)
    end
    
    def add(shipment_items_array)
      Fulfillment::Shipment.add(self.client, self.fulfillment_order['id'], self.public_id, shipment_items_array)
    end

    def close
      Fulfillment::Shipment.close(self.client, self.fulfillment_order['id'], self.public_id)
    end

    class << self

      def add(client, order_public_id, shipment_public_id, shipment_items_array)
        shipment_payload = { "fulfillment_order_items" => shipment_items_array }
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{order_public_id}/shipments/#{shipment_public_id}/add"), shipment_payload.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::ClientException.new("Could not add shipment information about shipment #{shipment_public_id} to order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      def create(client, order_public_id, shipment_hash)
        curl = Curl::Easy.http_post(client.build_auth_url("/orders/#{order_public_id}/shipments"), shipment_hash.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not create shipment for order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 201

        new(client, JSON.parse(curl.body_str))
      end

      def shipment_items(client, shipment_public_id, first_page_num = 1)
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.http_get(client.build_auth_url("/shipments/#{shipment_public_id}/items")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
          end

          raise Fulfillment::ClientException.new("Could not load index of items for shipment #{shipment_public_id}: \n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

          shipment_items_hashes = JSON.parse(curl.body_str)
          result = shipment_items_hashes.map { |sh| Fulfillment::ShipmentItem.new(client, sh) }

          Fulfillment::PagingEnvelope.envelop(curl, result)
        end
      end

      def show(client, shipment_public_id)
        curl = Curl::Easy.http_get(client.build_auth_url("/shipments/#{shipment_public_id}")) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::ClientException.new("Could not get shipment #{shipment_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      def list(client, first_page_num = 1)
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.http_get(client.build_auth_url("/shipments")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
          end
        
          raise Fulfillment::ClientException.new("Could not get index of shipments:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200
        
          shipment_hashes = JSON.parse(curl.body_str)
          result = shipment_hashes.map { |sh| new(client, sh) }
          
          Fulfillment::PagingEnvelope.envelop(curl, result)
        end  
      end

      def close(client, order_public_id, shipment_public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{order_public_id}/shipments/#{shipment_public_id}/close"), {}.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::ClientException.new("Could not close shipment #{shipment_public_id} for order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end
      
    end
  end
end
