require 'json'
require 'curb'
require 'openssl'
require 'active_support/core_ext/hash/indifferent_access'

%w(
  client
  client_exception
  creation_exception
  model_base
  order
  order_item
  paged_result
  paging_envelope
  search_exception
  shipment
  shipment_item
  version
).each do |file|
  require File.join(File.dirname(__FILE__), 'fulfillment', file)
end
