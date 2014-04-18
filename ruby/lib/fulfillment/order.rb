module Fulfillment
  class Order < ModelBase

    REJECT_CODE_BAD_ORDER_INFO = 1
    REJECT_CODE_GENERIC = 2
    REJECT_CODE_OUT_OF_STOCK = 3
    REJECT_CODES = [REJECT_CODE_BAD_ORDER_INFO, REJECT_CODE_GENERIC, REJECT_CODE_OUT_OF_STOCK]

    attr_accessor :client

    def initialize(client, data)
      @client = client
      make_getter_methods(data)
    end

    def order_items(first_page_num = 1)
      Fulfillment::OrderItem.list(self.client, self.public_id, first_page_num)
    end
    
    def process
      Fulfillment::Order.processing_transition(self.client, self.public_id)
    end

    def processed
      Fulfillment::Order.processed_transition(self.client, self.public_id)
    end

    def shipping
      Fulfillment::Order.shipping_transition(self.client, self.public_id)
    end

    def shipped
      Fulfillment::Order.shipped_transition(self.client, self.public_id)
    end
    
    def reject(rejected_code)
      Fulfillment::Order.reject(self.client, self.public_id, rejected_code)
    end
    
    def create_shipment(shipment_hash)
      Fulfillment::Shipment.create(self.client, self.public_id, shipment_hash)
    end
    
    def order_shipments
      Fulfillment::Order.order_shipments(self.client, self.public_id)
    end

    class << self
      def order_shipments(client, public_id, first_page_num = 1)
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.http_get(client.build_auth_url("/orders/#{public_id}/shipments")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
          end

          raise Fulfillment::ClientException.new("Could not load index of shipments for #{public_id}: \n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

          shipment_hashes = JSON.parse(curl.body_str)
          result = shipment_hashes.map { |sh| Fulfillment::Shipment.new(client, sh) }

          Fulfillment::PagingEnvelope.envelop(curl, result)
        end
      end
      
      def processing_transition(client, public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{public_id}/process"), {}) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not complete processing transition for #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end
      
      def processed_transition(client, public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{public_id}/processed"), {}) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not complete processed transition for #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end      
      
      def shipping_transition(client, public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{public_id}/shipping"), {}.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not create shipped transition for #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end
      
      def shipped_transition(client, public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{public_id}/shipped"), {}.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not create shipped transition for #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      ##
      # Reject the given FulfillmentOrder based on the public ID. The client must be the named
      # FulfillmentProvider in order for the "rejection" to be successful.
      def reject(client, public_id, rejected_code)
        raise ArgumentError.new("Invalid Reject Code. The following are valid reject codes #{REJECT_CODES.join(",")}") unless REJECT_CODES.include?(rejected_code)
        error_payload = {"rejected_code" => rejected_code}

        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{public_id}/reject"), error_payload.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not reject order for #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      def show(client, public_id)
        curl = Curl::Easy.http_get(client.build_auth_url("/orders/#{public_id}")) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::ClientException.new("Could not get Order #{public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      # return a collection of orders for fulfiller in ready status
      def ready(client, first_page_num = 1)
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.new(client.build_auth_url("/orders/ready")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
          end

          curl.perform
          ready_order_hashes = JSON.parse(curl.body_str)
          result = ready_order_hashes.map { |roh| new(client, roh) }

          Fulfillment::PagingEnvelope.envelop(curl, result)
        end
      end

      def search(client, search_options = {})
        first_page_num = 1
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.http_get(client.build_auth_url("/orders/search")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
            search_options.each { |k, v| client.add_query_parameter(curl, k, v) }
            curl
          end

          raise Fulfillment::SearchException.new("Could not search orders with search options #{search_options}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

          search_result_order_array = JSON.parse(curl.body_str)
          orders = []
          search_result_order_array.each { |oh| orders << new(client, oh) }

          Fulfillment::PagingEnvelope.envelop(curl, orders)
        end
      end

    end
  end
end
