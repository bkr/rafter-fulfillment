require 'spec_helper'

def create_add_response_json(client_reference_id, post_data)
  response_json = <<-END
  {
    "public_id":"FO1234567890",
    "created_at":"2012-12-12T16:42:57-08:00",
    "updated_at":"2012-12-12T16:42:57-08:00",
    "ship_date":"#{post_data['ship_date']}",
    "client_reference_id":"#{client_reference_id}",
    "started_processing":null,
    "fulfillment_provider":"#{post_data['fulfillment_provider']}",
    "fulfillment_tags":[
    ],
    "status":"new",
    "rejected_code":null,
    "fulfillment_shipping_address":{
      "name":"#{post_data['fulfillment_shipping_address']['name']}",
      "surname":"#{post_data['fulfillment_shipping_address']['surname']}",
      "street_address_1":"#{post_data['fulfillment_shipping_address']['street_address_1']}",
      "street_address_2":"#{post_data['fulfillment_shipping_address']['street_address_2']}",
      "city":"#{post_data['fulfillment_shipping_address']['city']}",
      "state":"#{post_data['fulfillment_shipping_address']['state']}",
      "postal_code":"#{post_data['fulfillment_shipping_address']['postal_code']}",
      "country":"#{post_data['fulfillment_shipping_address']['country']}"
    },
    "fulfillment_order_items":{
      "total":0,
      "shipped":0,
      "rejected":0,
      "location":"/orders/FO1234567890/items"
    },
    "fulfillment_shipments":{
      "total":0,
      "location":"/orders/FO1234567890/shipments"
    }
  }  
  END
  response_json
end 

describe Fulfillment::Order do
  before { @client = Fulfillment::Client.new(:api_key => '12345', :host => 'localhost:3000', :scheme => 'http') }

  describe ".show" do
    before :each do
      @curl = stub
      @public_id = '1'
      @response_json = <<-END
        {
          "public_id":"#{@public_id}",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"ready",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }
        END
      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json,
                              :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
    end

    it 'should return the order' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/orders/#{@public_id}").and_return(@curl)
      @response = Fulfillment::Order.show(@client,"1")
      @response.should be_a Fulfillment::Order
      @response.status.should eq 'ready'
    end
  end

  describe '#ready' do
    before do
      @curl = stub

      @response_json = <<-END
      [{
        "public_id":"FO-gibberish0123456",
        "fulfillment_provider":"Ingram",
        "expiration_date":"20130515",
        "client_reference_id":"FirstTestOrder",
        "fulfillment_tags":[],
        "status":"ready",
        "fulfillment_shipping_address":{
          "name":"#{Faker::Company.name}",
          "street_address_1":"#{Faker::Address.street_address}",
          "street_address_2":"#{Faker::Address.secondary_address}",
          "city":"#{Faker::Address.city}",
          "state":"#{Faker::Address.state_abbr}",
          "postal_code":"#{Faker::Address.zip_code}",
          "country":"USA"
        }
      }]
      END
      @curl.stub(:perform)
      @curl.stub(:response_code => 200)
      @curl.stub(:header_str).and_return("HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
      @curl.stub(:body_str => @response_json)
    end

    context 'with one order' do
      it 'returns one order' do
        Curl::Easy.should_receive(:new).with("http://localhost:3000/orders/ready").and_return(@curl)
        fulfillment_orders = Fulfillment::Order.ready(@client).results
        fulfillment_orders.first.should be_a Fulfillment::Order
        fulfillment_orders.size.should eq 1
      end
    end

    context "with no orders" do
      before do
        @response_json = "[]"
        @curl.stub(:body_str => @response_json)
      end

      it 'returns 0 orders' do
        Curl::Easy.should_receive(:new).with("http://localhost:3000/orders/ready").and_return(@curl)
        fulfillment_orders = Fulfillment::Order.ready(@client).results
        fulfillment_orders.size.should eq 0
      end
    end


    context "with two orders" do
      before do
        @response_json = <<-END
        [{
          "public_id":"FO-gibberish0123456",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"ready",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        },
        {
          "public_id":"FO-gobbledeg0123456",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"SecondTestOrder",
          "fulfillment_tags":[],
          "status":"ready",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }]
        END
        @curl.stub(:body_str => @response_json)
      end

      it 'returns 2 ready orders' do
        Curl::Easy.should_receive(:new).with("http://localhost:3000/orders/ready").and_return(@curl)
        fulfillment_orders = Fulfillment::Order.ready(@client).results
        fulfillment_orders[0].should be_a Fulfillment::Order
        fulfillment_orders[1].should be_a Fulfillment::Order
        fulfillment_orders.size.should eq 2
      end
    end
  end

  describe "transitions" do
    context 'processing transition' do
      before :each do
        @public_id = 1
        @response_json = <<-END
        {
          "public_id":"1",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"processing",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }
        END
        @curl = stub
        @curl.stub(:response_code => 200)
        @curl.stub(:perform)
        @curl.stub(:body_str => @response_json)
        @curl.stub(:header_str).and_return("HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
      end

      it "should respond with a processing Order" do
        Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@public_id}/process", {}).and_return(@curl)
        @fo = Fulfillment::Order.new(@client, {:public_id => @public_id})
        @response = @fo.process
        @response.should be_a Fulfillment::Order
        @response.status.should eq 'processing'
      end
    end

    context 'processed transition' do
      before :each do
        @public_id = 1
        @response_json = <<-END
        {
          "public_id":"1",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"processed",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }
        END
        @curl = stub
        @curl.stub(:response_code => 200)
        @curl.stub(:perform)
        @curl.stub(:body_str => @response_json)
        @curl.stub(:header_str).and_return("HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
      end

      it "should respond with a processing Order" do
        Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@public_id}/processed", {}).and_return(@curl)
        @fo = Fulfillment::Order.new(@client, {:public_id => @public_id})
        @response = @fo.processed
        @response.should be_a Fulfillment::Order
        @response.status.should eq 'processed'
      end
    end

    context 'shipped transition' do
      before :each do
        @public_id = 1
        @response_json = <<-END
        {
          "public_id":"1",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"shipped",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }
        END
        @curl = stub
        @curl.stub(:response_code => 200)
        @curl.stub(:perform)
        @curl.stub(:body_str => @response_json)
      end

      it "should respond with a shipped order" do
        Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@public_id}/shipped", {}.to_json).and_return(@curl)
        order = Fulfillment::Order.new(@client, {:public_id => @public_id})
        shipped_order = order.shipped
        shipped_order.should be_a Fulfillment::Order
        shipped_order.status.should eq 'shipped'
      end
    end
    
    context 'shipping transition' do
      before :each do
        @public_id = 1
        @response_json = <<-END
        {
          "public_id":"1",
          "fulfillment_provider":"Ingram",
          "expiration_date":"20130515",
          "client_reference_id":"FirstTestOrder",
          "fulfillment_tags":[],
          "status":"shipping",
          "fulfillment_shipping_address":{
            "name":"#{Faker::Company.name}",
            "street_address_1":"#{Faker::Address.street_address}",
            "street_address_2":"#{Faker::Address.secondary_address}",
            "city":"#{Faker::Address.city}",
            "state":"#{Faker::Address.state_abbr}",
            "postal_code":"#{Faker::Address.zip_code}",
            "country":"USA"
          }
        }
        END
        @curl = stub
        @curl.stub(:response_code => 200)
        @curl.stub(:perform)
        @curl.stub(:body_str => @response_json)
      end

      it "should respond with a shipping order" do
        Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@public_id}/shipping", {}.to_json).and_return(@curl)
        order = Fulfillment::Order.new(@client, {:public_id => @public_id})
        shipping_order = order.shipping
        shipping_order.should be_a Fulfillment::Order
        shipping_order.status.should eq 'shipping'
      end
    end
    
  end

  describe ".search" do
    before :each do
      @response_json = <<-END
      [{
        "public_id":"FO-gibberish0123456",
        "fulfillment_provider":"Ingram",
        "expiration_date":"20130515",
        "client_reference_id":"FirstTestOrder",
        "fulfillment_tags":[],
        "status":"ready",
        "fulfillment_shipping_address":{
          "name":"#{Faker::Company.name}",
          "street_address_1":"#{Faker::Address.street_address}",
          "street_address_2":"#{Faker::Address.secondary_address}",
          "city":"#{Faker::Address.city}",
          "state":"#{Faker::Address.state_abbr}",
          "postal_code":"#{Faker::Address.zip_code}",
          "country":"USA"
        }
      },
      {
        "public_id":"FO-gobbledeg0123456",
        "fulfillment_provider":"Ingram",
        "expiration_date":"20130515",
        "client_reference_id":"SecondTestOrder",
        "fulfillment_tags":[],
        "status":"ready",
        "fulfillment_shipping_address":{
          "name":"#{Faker::Company.name}",
          "street_address_1":"#{Faker::Address.street_address}",
          "street_address_2":"#{Faker::Address.secondary_address}",
          "city":"#{Faker::Address.city}",
          "state":"#{Faker::Address.state_abbr}",
          "postal_code":"#{Faker::Address.zip_code}",
          "country":"USA"
        }
      }]
      END
      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json,
                              :header_str => "HTTP/1.1 200 OK\r\nX-API-PAGINATION: {\"per_page\":100,\"total_pages\":1}")
      @search_options = {:fulfillment_status=>'ready'}
    end

    it 'should return the order' do
      Curl::Easy.should_receive(:http_get).with("http://localhost:3000/orders/search").and_yield(@curl)
      @client.should_receive(:configure_http).with(@curl)
      @client.should_receive(:set_request_page).with(@curl, 1)
      @client.should_receive(:add_query_parameter).with(@curl, :fulfillment_status, 'ready')
      @response = Fulfillment::Order.search(@client, @search_options)
      @response.should be_a Fulfillment::PagedResult
      @response.results.first.status.should eq 'ready'
    end
  end

  describe ".reject" do 
    before :each do
      @public_id = 'FO-gobbledeg0123456'
      @response_json = <<-END
      {
        "public_id":"#{@public_id}",
        "fulfillment_provider":"Ingram",
        "expiration_date":"20130515",
        "client_reference_id":"SecondTestOrder",
        "fulfillment_tags":[],
        "status":"rejected",
        "fulfillment_shipping_address":{
          "name":"#{Faker::Company.name}",
          "street_address_1":"#{Faker::Address.street_address}",
          "street_address_2":"#{Faker::Address.secondary_address}",
          "city":"#{Faker::Address.city}",
          "state":"#{Faker::Address.state_abbr}",
          "postal_code":"#{Faker::Address.zip_code}",
          "country":"USA"
        }
      }
      END
      
      @curl = double( 'curl', :response_code => 200,
                              :body_str => @response_json)
    end
    it 'should return the order with a rejected status' do
      Curl::Easy.should_receive(:http_put).with("http://localhost:3000/orders/#{@public_id}/reject", {'rejected_code' => 1 }.to_json).and_return(@curl)
      order = Fulfillment::Order.reject(@client, @public_id, 1)                     
      order.should be_an Fulfillment::Order
      order.status.should eq 'rejected'
    end
  end
  
end
