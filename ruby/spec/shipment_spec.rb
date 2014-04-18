require 'spec_helper'

describe Fulfillment::Shipment do
  before { @client = Fulfillment::Client.new(:api_key => '12345', :host => 'localhost:3000', :scheme => 'http') }

  before :each do
    @order_public_id = "FO1234567890"
  end
  
  context '.create' do
    before :each do
      @post_data = mock_shipment_data(["FI123","FI456"])
      @post_data['shipment_reference_id'] = 'FAKE_SHIP_1067'
      @post_json = @post_data.to_json
      @response_json = <<-END
      {
        "public_id":"FS5ca30b22132d7bc9",
        "created_at":"2012-12-10T21:19:42-08:00",
        "updated_at":"2012-12-10T21:19:42-08:00",
        "shipment_reference_id":"FAKE_SHIP_1067",
        "tracking_number":"1Z1234567",
        "carrier":"UPS",
        "carrier_code":"Second Day",
        "fulfillment_order":"#{@order_public_id}",
        "fulfillment_order_items":{
          "total":1,
          "location":"/shipments/FS5ca30b22132d7bc9/items"
        }
      }
      END
      @response_code = 201
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json)
    end
    
    it 'creates a shipment for an order' do
      Curl::Easy.should_receive(:http_post).with("http://localhost:3000/orders/#{@order_public_id}/shipments", @post_json).and_return(@curl)
      shipment = Fulfillment::Shipment.create(@client, @order_public_id, @post_data)
      shipment.should be_a Fulfillment::Shipment
      shipment.shipment_reference_id.should eq @post_data['shipment_reference_id']
      shipment.fulfillment_order.should eq @order_public_id
      shipment.fulfillment_order_items['total'].should eq 1
    end
    
  end

  context '.add' do
    
    before :each do
      @shipment_public_id = "FS1234567890"
      @post_data = mock_shipment_item_data(["FI123","FI456"])
      @post_json = {"fulfillment_order_items" => @post_data}.to_json
      @response_json = <<-END
      {
        "public_id":"#{@shipment_public_id}",
        "created_at":"2012-12-10T21:19:42-08:00",
        "updated_at":"2012-12-10T21:19:42-08:00",
        "shipment_reference_id":"FAKE_SHIP_1067",
        "tracking_number":"1Z1234567",
        "carrier":"UPS",
        "carrier_code":"Second Day",
        "fulfillment_order":"#{@order_public_id}",
        "fulfillment_order_items":{
          "total":2,
          "location":"/shipments/FS5ca30b22132d7bc9/items"
        }
      }
      END
      @response_code = 200
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json)
      
    end
    
    it 'adds to an existing shipment' do
      Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/shipments/#{@shipment_public_id}/add", @post_json).and_return(@curl)
      shipment = Fulfillment::Shipment.add(@client, @order_public_id, @shipment_public_id, @post_data)
      shipment.should be_a Fulfillment::Shipment
      shipment.shipment_reference_id.should eq 'FAKE_SHIP_1067'
      shipment.fulfillment_order.should eq @order_public_id
      shipment.fulfillment_order_items['total'].should eq 2
    end
    
  end
  
  context '.shipment_items' do
    
    before :each do 
      @curl = stub
      @order_item_public_id_1 = "FO111"
      @order_item_public_id_2 = "FO222"
      @shipment_public_id = "FS1234567890"
      @response_json = <<-END
      [
        {
          "created_at":"2012-12-12T15:02:11-08:00",
          "updated_at":"2012-12-12T15:02:11-08:00",
          "fulfillment_shipment":{
            "public_id":"#{@shipment_public_id}",
            "location":"/shipments/#{@shipment_public_id}"
          },
          "fulfillment_order":{
            "public_id":"#{@order_public_id}",
            "location":"/orders/#{@order_public_id}"
          },
          "fulfillment_order_item":{
            "public_id":"#{@order_item_public_id_1}",
            "location":"/orders/#{@order_public_id}/items/#{@order_item_public_id_1}"
          }
        },
        {
          "created_at":"2012-12-12T15:02:11-08:00",
          "updated_at":"2012-12-12T15:02:11-08:00",
          "fulfillment_shipment":{
            "public_id":"#{@shipment_public_id}",
            "location":"/shipments/#{@shipment_public_id}"
          },
          "fulfillment_order":{
            "public_id":"#{@order_public_id}",
            "location":"/orders/#{@order_public_id}"
          },
          "fulfillment_order_item":{
            "public_id":"#{@order_item_public_id_2}",
            "location":"/orders/#{@order_public_id}/items/#{@order_item_public_id_2}"
          }
        }
      ]
      END
      @response_code = 200
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json, :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end

    it 'presents a list of shipment items' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/shipments/#{@shipment_public_id}/items").and_return(@curl)
      shipment_items = Fulfillment::Shipment.shipment_items(@client, @shipment_public_id)
      shipment_items.should be_a Fulfillment::PagedResult
      shipment_items_results = shipment_items.results
      shipment_items_results.size.should eq 2
      shipment_items_results.first.should be_a Fulfillment::ShipmentItem
      shipment_items_results.first.fulfillment_shipment['public_id'].should eq @shipment_public_id      
      shipment_items_results.first.fulfillment_order_item['public_id'].should eq @order_item_public_id_1
      shipment_items_results.first.fulfillment_order['public_id'].should eq @order_public_id
    end  
  end
  
  context '.show' do
    before :each do
      @shipment_public_id = 'FS1234567890'
      @response_json = <<-END
      {
        "public_id":"#{@shipment_public_id}",
        "created_at":"2012-12-10T21:33:24-08:00",
        "updated_at":"2012-12-10T21:41:53-08:00",
        "shipment_reference_id":"FAKE_SHIP_7289",
        "tracking_number":"1Z1234567",
        "carrier":"UPS",
        "carrier_code":"Second Day",
        "fulfillment_order":"#{@order_public_id}",
        "fulfillment_order_items":{
          "total":2,
          "location":"/shipments/FSfadfaf2aee509789/items"
        }
      }
      END
      @response_code = 200
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json)
    end

    it 'can show an order by shipment id' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/shipments/#{@shipment_public_id}").and_return(@curl)
      shipment = Fulfillment::Shipment.show(@client, @shipment_public_id)
      shipment.should be_a Fulfillment::Shipment
      shipment.public_id.should eq @shipment_public_id
      shipment.fulfillment_order.should eq @order_public_id
    end  
  end
  
  context '.list' do
    before :each do
      @shipment_public_id_1 = "FS1234567890"
      @shipment_public_id_2 = "FS0987654321"
      @response_json = <<-END
      [
        {
          "public_id":"#{@shipment_public_id_1}",
          "created_at":"2012-12-10T21:33:24-08:00",
          "updated_at":"2012-12-10T21:41:53-08:00",
          "shipment_reference_id":"FAKE_SHIP_7289",
          "tracking_number":"1Z1234567",
          "carrier":"UPS",
          "carrier_code":"Second Day",
          "fulfillment_order":"FO111",
          "fulfillment_order_items":{
            "total":2,
            "location":"/shipments/#{@shipment_public_id_1}/items"
          }
        },  
        {
          "public_id":"#{@shipment_public_id_2}",
          "created_at":"2012-12-10T21:33:24-08:00",
          "updated_at":"2012-12-10T21:41:53-08:00",
          "shipment_reference_id":"FAKE_SHIP_7290",
          "tracking_number":"1Z1234567",
          "carrier":"UPS",
          "carrier_code":"Second Day",
          "fulfillment_order":"FO222",
          "fulfillment_order_items":{
            "total":2,
            "location":"/shipments/#{@shipment_public_id_2}/items"
          }
        }
      ]
      END
      @response_code = 200
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json, :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end
    
    it 'can list all shipments' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/shipments").and_return(@curl)
      shipments = Fulfillment::Shipment.list(@client)
      shipments.should be_a Fulfillment::PagedResult
      shipments_results = shipments.results
      shipments_results.first.should be_a Fulfillment::Shipment
      shipments_results.first.public_id.should eq @shipment_public_id_1        
      shipments_results.last.public_id.should eq @shipment_public_id_2
    end
  end

  context '.close' do
    before :each do
      @order_public_id = 'FO123'
      @shipment_public_id = 'FS456'
      @response_json = <<-END
      {
        "public_id":"#{@shipment_public_id}",
        "created_at":"2012-12-10T21:33:24-08:00",
        "updated_at":"2012-12-10T21:41:53-08:00",
        "shipment_reference_id":"FAKE_SHIP_7289",
        "tracking_number":"1Z1234567",
        "status":"closed",
        "carrier":"UPS",
        "carrier_code":"Second Day",
        "fulfillment_order":"#{@order_public_id}",
        "fulfillment_order_items":{
          "total":100,
          "location":"/shipments/FSfadfaf2aee509789/items"
        }
      }
      END
      @response_code = 200
      @curl = double('curl', :response_code => @response_code, :body_str => @response_json)
    end

    it "should return a ready Order" do
      Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@order_public_id}/shipments/#{@shipment_public_id}/close", {}.to_json).and_return(@curl)
      shipment = Fulfillment::Shipment.close(@client, @order_public_id, @shipment_public_id)
      shipment.should be_a Fulfillment::Shipment
      shipment.status.should eq 'closed'
    end
  end
end
