module Fulfillment
  class OrderItem < ModelBase

    attr_accessor :client, :order_public_id

    GENERIC_REJECTION = 1 # un-categorized rejection reason
    OUT_OF_STOCK_REJECTION = 2 # fulfillment provider is temporarily out of stock
    ITEM_NOT_STOCKED_REJECTION = 3 # fulfillment provider does not know about this item at all
    RESERVE_EXHAUSTED_REJECTION = 4
    INVALID_QUANTITY_REJECTION = 5
    REJECT_CODES = [GENERIC_REJECTION, OUT_OF_STOCK_REJECTION,
                    ITEM_NOT_STOCKED_REJECTION, RESERVE_EXHAUSTED_REJECTION,
                    INVALID_QUANTITY_REJECTION]

    def initialize(client, data)
      @client = client
      make_getter_methods(data)
    end

    def reject(rejected_code)
      Fulfillment::OrderItem.reject(self.client, self.order_public_id, self.public_id, rejected_code)
    end

    def acknowledge(acknowledgements)
      Fulfillment::OrderItem.acknowledge(self.client, self.order_public_id, self.public_id, acknowledgements)
    end

    def process
      Fulfillment::OrderItem.process(self.client, self.order_public_id, self.public_id)
    end

    class << self

      ##
      # Acknowledge quantites accepted / rejected of the given FulfillmentOrderItem based on the FulfillmentOrder public ID
      # and the FulfillmentOrderItem public ID.
      # Accepted and Rejected quantities must be present in the acknowledgements hash
      def acknowledge(client, order_public_id, order_item_public_id, acknowledgements)
        payload = HashWithIndifferentAccess.new(acknowledgements)
        if payload[:quantity_accepted].nil? || payload[:quantity_rejected].nil?
          raise ArgumentError.new("Accepted and Rejected quantities must be present in the acknowledgements hash.")
        end

        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{order_public_id}/items/#{order_item_public_id}/acknowledge"), acknowledgements.to_json) do |curl|
          client.configure_http(curl)
        end

        if curl.response_code != 200
          raise Fulfillment::CreationException.new("Could not acknowledge item #{order_item_public_id} from order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}")
        end

        new(client, JSON.parse(curl.body_str))
      end

      ##
      # Reject the given FulfillmentOrderItem based on the FulfillmentOrder public ID and the FulfillmentOrderItem
      # public ID. The client must be the named FulfillmentProvider in order for the "rejection" to be successful.
      def reject(client, order_public_id, order_item_public_id, rejected_code)
        raise ArgumentError.new("Invalid Reject Code. The following are valid reject codes #{REJECT_CODES.join(",")}") unless REJECT_CODES.include?(rejected_code)
        error_payload = {"rejected_code" => rejected_code}

        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{order_public_id}/items/#{order_item_public_id}/reject"), error_payload.to_json) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not reject item #{order_item_public_id} from order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      ##
      # Process a given FulfillmentOrderItem based on the FulfillmentOrder public_id and the FulfillmentOrderItem
      # public_id. The client must be the named FulfillmentProvider in order for the 'process' to be successful.
      def process(client, order_public_id, order_item_public_id)
        curl = Curl::Easy.http_put(client.build_auth_url("/orders/#{order_public_id}/items/#{order_item_public_id}/process"), {}) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::CreationException.new("Could not process item #{order_item_public_id} from order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        new(client, JSON.parse(curl.body_str))
      end

      def list(client, order_public_id, first_page_num = 1)
        Fulfillment::PagedResult.construct(first_page_num) do |page_num|
          curl = Curl::Easy.http_get(client.build_auth_url("/orders/#{order_public_id}/items")) do |curl|
            client.configure_http(curl)
            client.set_request_page(curl, page_num)
          end

          raise Fulfillment::ClientException.new("Could not load index of items for order #{order_public_id}: \n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

          order_item_result_array = JSON.parse(curl.body_str)
          order_items = []
          order_item_result_array.each do |ira|
            order_item = new(client, ira)
            order_item.order_public_id = order_public_id
            order_items << order_item
          end

          Fulfillment::PagingEnvelope.envelop(curl, order_items)
        end
      end

      def show(client, order_public_id, order_item_public_id)
        curl = Curl::Easy.http_get(client.build_auth_url("/orders/#{order_public_id}/items/#{order_item_public_id}")) do |curl|
          client.configure_http(curl)
        end

        raise Fulfillment::ClientException.new("Could not get order item #{order_item_public_id} for order #{order_public_id}:\n\n Response Body:\n #{curl.body_str}") unless curl.response_code == 200

        order_item = new(client, JSON.parse(curl.body_str))
        order_item.order_public_id = order_public_id
        order_item
      end

    end
  end
end