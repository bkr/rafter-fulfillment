require 'cgi'

module Fulfillment
  class Client

    attr_accessor :verbose, :logger
    attr_reader :api_key, :host, :base_uri, :scheme

    DEFAULT_TIMEOUT = 10

    def initialize(options = {})
      client_options = HashWithIndifferentAccess.new(options)
      @api_key = client_options[:api_key].nil? ? (raise ArgumentError.new(":api_key is a required argument")) : client_options[:api_key]
      @host = client_options[:host].nil? ? (raise ArgumentError.new(":host is a required argument")) : client_options[:host]
      @scheme = client_options[:scheme] || "https"
      @base_uri = @scheme + "://" + @host
      @verbose = client_options[:verbose] || false
      @logger = client_options[:logger] || nil
      @timeout = client_options[:timeout] || DEFAULT_TIMEOUT
    end

    def configure_http(http)
      http.headers["X-API-KEY"] = @api_key
      http.headers["Accept"] = Fulfillment::API_VERSION
      http.headers["Content-Type"] = "application/json"
      if scheme == "https"
        http.use_ssl = Curl::CURL_USESSL_ALL
        http.ssl_verify_peer = false
      end
      http.verbose = @verbose
      unless @logger.nil?
        http.on_debug { |type,data| @logger.info "Fulfillment Client #{data}" }
      end
      http.timeout = @timeout
    end
    
    def build_auth_url(resource_path)
      @base_uri + resource_path
    end

    def add_query_parameter(curl, key, value)
      current_url = curl.url
      curl.url = current_url + (current_url.match(/\?/) ? "&" : "?") + "#{CGI::escape key.to_s}=#{CGI::escape value.to_s}"
    end
    
    def set_request_page(curl, page_num)
      add_query_parameter(curl, "page", page_num)
    end
  end
end