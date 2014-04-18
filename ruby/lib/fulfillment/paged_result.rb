module Fulfillment
  class PagedResult
    include Enumerable

    attr_reader :first_page_num

    # Create a

    # *first_page_number* is the starting page for the associated API call.
    # *api_caller_proc* is a Proc that returns a hash (of the type returned
    #     by Exchange::PagingEnvelope.envelope).  Calling the proc and passing
    #     it a page_number should return an enveloped API call result.
    def initialize(first_page_num, api_caller_proc)
      @first_page_num = first_page_num
      @api_caller_proc = api_caller_proc
    end

    def pages
      entries
    end

    def results
      pages.flatten
    end

    def each
      page_num = @first_page_num
      enveloped_page = @api_caller_proc.call(page_num)
      yield enveloped_page[:data]
      while (page_num < enveloped_page[:total_pages])
        page_num += 1
        enveloped_page = @api_caller_proc.call(page_num)
        yield enveloped_page[:data]
      end
    end

    class << self

      # Alternative constructor that takes a block rather than a Proc instance
      def construct(first_page_num, &api_caller_proc)
        new(first_page_num, api_caller_proc)
      end
    end
  end
end