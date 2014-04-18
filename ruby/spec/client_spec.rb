require 'spec_helper'

describe Fulfillment::Client do
  before :each do
    @client = Fulfillment::Client.new(:host => "fulfillment-test.rafter.com", :api_key => "xyz123abc")
  end
  
  it 'makes the host and api_key a readable attribute' do
    @client.host.should eq "fulfillment-test.rafter.com"
    @client.api_key.should eq "xyz123abc"
  end

  it 'returns the base URI' do
    @client.base_uri.should eq "https://fulfillment-test.rafter.com"
  end

  it 'raises an ArgumentError if the host argument is missing' do
    lambda { Fulfillment::Client.new(:api_key => "xyz123abc") }.should raise_error(ArgumentError, ":host is a required argument")
  end

  it 'raises an ArgumentError if the api_key argument is missing' do
    lambda { Fulfillment::Client.new(:host => "exchange-test.rafter.com") }.should raise_error(ArgumentError, ":api_key is a required argument")
  end
  
  it 'raises a TimeoutError if the timeout is exceeded' do
    lambda {
      @client = Fulfillment::Client.new(:host => '10.201.202.203', :api_key => @client.api_key, :timeout => 1)
      Fulfillment::Order.show(@client, 'TEST42')      
    }.should raise_error(Curl::Err::TimeoutError)
  end
  
  describe ".build_auth_url" do
    it 'builds correct auth url with api_key' do
      @client.build_auth_url("/bin").should eq "https://fulfillment-test.rafter.com/bin"
    end
  end
  
  describe ".set_request_page" do
    it 'adds page parameter to url' do
      curl = Curl::Easy.new(@client.build_auth_url("/base_url"))
      @client.set_request_page(curl, 12).should eq "https://fulfillment-test.rafter.com/base_url?page=12"
      curl.url.should eq "https://fulfillment-test.rafter.com/base_url?page=12"
    end
  end
  
  describe ".add_query_parameter" do
    it 'adds query parameter to url when no parameters existed' do
      curl = Curl::Easy.new("https://fulfillment-test.rafter.com/base_url")
      @client.add_query_parameter(curl, "dummy_key", "dummy_value").should eq "https://fulfillment-test.rafter.com/base_url?dummy_key=dummy_value"
      curl.url.should eq "https://fulfillment-test.rafter.com/base_url?dummy_key=dummy_value"
    end

    it 'adds query parameter to url when parameters existed' do
      curl = Curl::Easy.new(@client.build_auth_url("/base_url"))
      @client.add_query_parameter(curl, "dummy_key", "dummy_value").should eq "https://fulfillment-test.rafter.com/base_url?dummy_key=dummy_value"
      curl.url.should eq "https://fulfillment-test.rafter.com/base_url?dummy_key=dummy_value"
    end
    
    it 'escapes unfriendly characters' do
      client = Fulfillment::Client.new(:host => "fulfillment-test.rafter.com", :api_key => "xyz123abc")
      curl = Curl::Easy.new(client.build_auth_url("/base_url"))
      client.add_query_parameter(curl, "dummy key", "dummy value").should eq "https://fulfillment-test.rafter.com/base_url?dummy+key=dummy+value"
    end
  end
end