require 'spec_helper'

describe Fulfillment::OrderItem do
  before :each do
    @client = Fulfillment::Client.new(:api_key => '12345', :host => 'localhost:3000', :scheme => 'http')

    @order_public_id = 'FO-gobbledeg0123456'
  end

  describe ".list" do
    before :each do
      @response_json = <<-END
      [
        {
          "public_id":"FOI0d9932",
          "created_at":"2012-12-07T00:07:43-08:00",
          "updated_at":"2012-12-07T00:09:20-08:00",
          "fulfillable_id":3493,
          "fulfillable_type":"BookInstance",
          "rejected":false,
          "rejected_code":null,
          "quantity_accepted":2,
          "quantity_rejected":3,
          "fulfillment_shipments":[{
                      "public_id":"FSee4e3d829a183c21",
                      "location":"/shipments/FSee4e3d829a183c21"
                    }]
        },
        {
          "public_id":"FOIc2da7f",
          "created_at":"2012-12-07T00:07:43-08:00",
          "updated_at":"2012-12-07T00:09:20-08:00",
          "fulfillable_id":4611,
          "fulfillable_type":"BookInstance",
          "rejected":false,
          "rejected_code":null,
          "quantity_accepted":2,
          "quantity_rejected":3,
          "fulfillment_shipments":[{
                      "public_id":"FSee4e3d829a183c21",
                      "location":"/shipments/FSee4e3d829a183c21"
                    }]
        }
      ]
      END
      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json,
                              :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end

    it 'should return a list of order items' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/orders/#{@order_public_id}/items").and_return(@curl)
      order_items = Fulfillment::OrderItem.list(@client, @order_public_id)
      order_items.should be_a Fulfillment::PagedResult
      results = order_items.results
      results.size.should eq 2
      results.first.should be_a Fulfillment::OrderItem
    end
  end

  describe ".show" do
    before :each do
      @order_item_public_id = "FOI1234567890"
      @response_json = <<-END
      {
        "public_id":"#{@order_item_public_id}",
        "created_at":"2012-12-07T00:07:43-08:00",
        "updated_at":"2012-12-07T00:09:20-08:00",
        "fulfillable_id":3493,
        "fulfillable_type":"BookInstance",
        "rejected":false,
        "rejected_code":null,
        "quantity_accepted":2,
        "quantity_rejected":3,
        "fulfillment_shipments":[{
                  "public_id":"FSee4e3d829a183c21",
                  "location":"/shipments/FSee4e3d829a183c21"
                }]
      }
      END

      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json)
    end

    it 'should return an individual order item' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/orders/#{@order_public_id}/items/#{@order_item_public_id}").and_return(@curl)
      order_item_result = Fulfillment::OrderItem.show(@client, @order_public_id, @order_item_public_id)
      order_item_result.should be_a Fulfillment::OrderItem
      order_item_result.public_id.should eq @order_item_public_id
    end
  end

  describe ".acknowledge" do
    context "with valid keys" do
      before :each do
        @order_item_id = 'FOI517513'
        @response_json = <<-END
        {
          "public_id":"#{@order_item_id}",
          "created_at":"2012-12-05T16:28:23-08:00",
          "updated_at":"2012-12-05T16:28:23-08:00",
          "fulfillable_id":3493,
          "fulfillable_type":"BookInstance",
          "rejected":false,
          "rejected_code":null,
          "quantity_accepted":2,
          "quantity_rejected":3,
          "fulfillment_shipments":[]
        }
        END

        @curl = double( 'curl', :response_code => response_code,
                                :body_str => @response_json,
                                :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
      end

      context "returns 500" do
        let(:response_code) { 500 }

        it 'should raise error' do
          Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/items/#{@order_item_id}/acknowledge", {"quantity_accepted" => 2, "quantity_rejected" => 1}.to_json).and_return(@curl)
          expect{Fulfillment::OrderItem.acknowledge(@client, @order_public_id, @order_item_id, {"quantity_accepted" => 2, "quantity_rejected" => 1})}.to raise_error(Fulfillment::CreationException)
        end
      end

      context "returns 200" do
        let(:response_code) { 200 }

        it 'should return the order item with acknowledgements' do
          Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/items/#{@order_item_id}/acknowledge", {"quantity_accepted" => 2, "quantity_rejected" => 1}.to_json).and_return(@curl)
          order_item = Fulfillment::OrderItem.acknowledge(@client, @order_public_id, @order_item_id, {"quantity_accepted" => 2, "quantity_rejected" => 1})
          order_item.quantity_accepted.should eq 2
          order_item.quantity_rejected.should eq 3
        end
      end
    end

    context "without valid keys" do
      it 'should return the order item with acknowledgements' do
        Curl::Easy.should_receive(:http_put).never
        expect {Fulfillment::OrderItem.acknowledge(@client, @order_public_id, @order_item_id, {"quantity_accepted" => 2})}.to raise_error(ArgumentError)
      end
    end
  end

  describe ".reject" do
    before :each do
      @order_item_id = 'FOI517513'
      @response_json = <<-END
      {
        "public_id":"#{@order_item_id}",
        "created_at":"2012-12-05T16:28:23-08:00",
        "updated_at":"2012-12-05T16:28:23-08:00",
        "fulfillable_id":2777,
        "fulfillable_type":"BookInstance",
        "status":"rejected",
        "rejected_code":2,
        "quantity_accepted":2,
        "quantity_rejected":3,
        "fulfillment_shipments":[]
      }
      END

      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json,
                              :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end

    it 'should return the order item with a rejected status' do
      Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/items/#{@order_item_id}/reject", {'rejected_code' => 2}.to_json).and_return(@curl)
      order_item = Fulfillment::OrderItem.reject(@client, @order_public_id, @order_item_id, 2)
      order_item.status.should eq 'rejected'
      order_item.rejected_code.should eq 2
    end
  end

  describe ".process" do
    before :each do
      @order_item_id = 'FOI517513'
      @response_json = <<-END
      {
        "public_id":"#{@order_item_id}",
        "created_at":"2012-12-05T16:28:23-08:00",
        "updated_at":"2012-12-05T16:28:23-08:00",
        "fulfillable_id":2777,
        "fulfillable_type":"BookInstance",
        "status":"processing",
        "quantity_accepted":2,
        "quantity_rejected":3,
        "fulfillment_shipments":[]
      }
      END

      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json,
                              :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end

    it 'should return the order item with a processing status' do
      Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/items/#{@order_item_id}/process", {}).and_return(@curl)
      order_item = Fulfillment::OrderItem.process(@client, @order_public_id, @order_item_id)
      order_item.status.should eq 'processing'
    end
  end

end
