module Fulfillment
  module PagingEnvelope
    class << self

      # Returns a hash like {per_page:100, total_pages:5, data: data}
      def envelop(curl, data)
        per_page, total_pages = get_pages_from_curl(curl)
        {per_page: per_page, total_pages: total_pages, data: data}
      end

      private

      def get_paging_json_from_response_header(response_header)
        if response_header.is_a? String
          get_paging_json_from_response_header(response_header.split)
        elsif response_header.count == 0
          nil
        elsif response_header[0].upcase == "X-API-PAGINATION:"
          response_header[1]
        else
          get_paging_json_from_response_header(response_header[1..-1])
        end
      end

      def get_pages_from_curl(curl_response)
        response_header = curl_response.header_str
        if (paging_json = get_paging_json_from_response_header(response_header))
          paging_hash = JSON.parse(paging_json)
          [paging_hash["per_page"], paging_hash["total_pages"]]
        else
          [nil, nil]
        end
      end
    end
  end
end