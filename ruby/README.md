# Rafter Fulfillment Client

## Examples

Please note that the examples provided below are intended to be an interaction blueprint and are subject to change.

# Rafter-Fulfillment installation & initialization

To use the Rafter fulfillment client, install with:
```ruby
gem install rafter-fulfillment
```

To initialize the client do the following in Ruby:
```ruby
@client = Fulfillment::Client.new(:api_key => 'API-KEY', :host => 'FULFILLMENT-HOST')

```API-KEY``` will be given to you by your Rafter technical contact.
```FULFILLMENT-HOST``` will be fulfillment-service.rafter.com for Rafter's production environment.

# Order methods

### Fulfillment::Order.show(client, public_id)
Shows an order. Response includes resource location information to the order's OrderItems.
```ruby
order = Fulfillment::Order.show(@client, @public_id)
```

### Fulfillment::Order.search(@client, search\_options\_hash)
Search for orders matching parameters passed in search\_options\_hash.  The resource will be a PagedResult of Orders.
```ruby
search_options_hash = {
  :client_reference_id => 'TEST_ORDER_42'
}
@orders = Fulfillment::Order.search(@client, search_options_hash)
```

### Fulfillment::Order.reject(@client, public\_id, rejected\_code)
Rejects an order given order\_public\_id. Only orders in the processing status can be rejected.
Orders will acknowledged order items cannot be rejected.
```ruby
rejected_order = Fulfillment::Order.reject(@client, @order.public_id, @order_item.public_id, 1)
```
OR
```ruby
rejected_order = @order.reject(Fulfillment::Order::REJECT_OUT_OF_STOCK)
```

Possible rejected\_codes are as follows:
```ruby
REJECT_CODE_BAD_ORDER_INFO = 1 # invalid order information
REJECT_CODE_GENERIC = 2
REJECT_CODE_OUT_OF_STOCK = 3 # fulfillment provider is temporarily out of stock
```

### Fulfillment::Order.processing\_transition(client, public_id)
Moves a ready order into the processing state.
This should be done on an order in the ready state to acknowledge it for processing.
Only the authenticated fulfillment_provider can call this method.
```ruby
processing_order = Fulfillment::Order.processing_transition(@client, @public_id)
```
OR
```ruby
processing_order = order.process
```

### Fulfillment::Order.shipping\_transition(client, public_id)
Moves a processing order into the shipping state.
This should be done on an order in the processing state to indicate it is ready for further shipment information.
Only the authenticated fulfillment_provider can call this method.
```ruby
shipping_order = Fulfillment::Order.shipping_transition(@client, @public_id)
```
OR
```ruby
shipping_order = order.shipping
```

### Fulfillment::Order.shipped\_transition(client, public_id, order_shipment_hashes_array)
Moves a shipping order into the shipped state. This should be done on an order in the shipping state.
Only the authenticated fulfillment_provider can call this method.
```ruby
shipped_order = Fulfillment::Order.shipped_transition(@client, @public_id)
```
OR
```ruby
shipped_order = order.shipped
```

# Order Item methods

### Fulfillment::OrderItem.show(client, order\_public\_id, order\_item\_public\_id)
Shows an OrderItem given order_public_id.
```ruby
order_item = Fulfillment::OrderItem.show(@client, @order.public_id, order_item_public_id)
```

### Fulfillment::OrderItem.list(client, order\_public\_id)

List all OrderItems for order_public_id.  Resource returned will be a PagedResult of OrderItems.
```ruby
order_items = Fulfillment::OrderItem.list(@client, @order.public_id).results
```
OR
```ruby
order_items = @order.order_items.results
```

### Fulfillment::OrderItem.process(client, order\_public\_id, order\_item\_public_id)

* Moves a RafterItem to processing status given order\_public\_id.
* Sets RafterItem quantity_requested to quantity_accepted.
* SupplyItem's should not use this method. Use Fulfillment::OrderItem.acknowledge.

```ruby
processing_order_item = Fulfillment::OrderItem.process(@client, @order.public_id, @order_item.public_id)
```
OR
```ruby
processing_order_item = @order_item.process
```

### Fulfillment::OrderItem.acknowledge(client, order\_public\_id, order\_item\_public_id, acknowledgements)```

* Acknowledges SupplyItem quantity given order\_public\_id.
* Order must be **ready** or **processing**
* If quantity_rejected equals the quantity_requested that the OrderItem was created with then the OrderItem will be marked as rejected.
* Will error if quantity_accepted is decreased for an Order Item.

```ruby
acknowledgement_hash = {"quantity_accepted" => 3, "quantity_rejected" => 0}
order_item = Fulfillment::OrderItem.acknowledge(@client, @order.public_id, @order_item.public_id, acknowledgement_hash)
```
OR
```ruby
order_item_with_acknowledgements = @order_item.acknowledge({"quantity_accepted" => 10, "quantity_rejected" => 2})
```

### Fulfillment::OrderItem.reject(client, order\_public\_id, order\_item\_public_id, rejected\_code)```

* Rejects an OrderItem given order\_public\_id.
* Cannot be rejected if previously acknowledged with a quantity_accepted greater than 0.
* Sets quantity_rejected to quantity_requested.

```ruby
rejected_order_item = Fulfillment::OrderItem.reject(@client, @order.public_id, @order_item.public_id, 1)
```
OR
```ruby
rejected_order_item = @order_item.reject(rejected_code)
```

Possible rejected\_codes are as follows:
```ruby
GENERIC_REJECTION = 1 # un-categorized rejection reason
OUT_OF_STOCK_REJECTION = 2 # fulfillment provider is temporarily out of stock
ITEM_NOT_STOCKED_REJECTION = 3 # fulfillment provider does not know about this item at all
RESERVE_EXHAUSTED_REJECTION = 4
INVALID_QUANTITY_REJECTION = 5
```

# Shipment methods


### Fulfillment::Shipment.create(client, order_public_id, shipment_hash)

Creates shipping information for an existing order.  The order must be in the shipping state.

* The shipment\_hash must contain a ship\_date, tracking\_number, carrier, carrier\_code, a client\_reference\_id, and a fulfillment\_order\_items element containing a list of public IDs that correspond to order line items.  
* Fulfillment\_order\_items may not be an empty array.  
* Limited to 100 fulfillment order items on the initial create.  
* A Shipment resource is returned. 
* If quantity\_shorted is not provided it will be defaulted to 0. 
* If quantity\_shipped is not provided it will be defaulted to 1.
* Will not create Shipment if ShipmentItems are created with more quantity_shipped than quantity_accepted on an OrderItem.

```ruby
shipment_hash = {
  :tracking_number => '1Z1234567',
  :carrier => 'UPS',
  :carrier_code => 'Second Day',
  :shipment_reference_id => 'TEST_SHIP_6',
  :fulfillment_order_items => [
    {
      :public_id => 'FOIfb27e0',
      :quantity_shipped => '2',
      :quantity_shorted => '1'
    },
    {
      :public_id => 'FOI4eeae3'
    }
  ]
}
shipment = Fulfillment::Shipment.create(@client, @order.public_id, shipment_hash)
```

###Fulfillment::Shipment.show(client, shipment_public_id)

Shows a shipment. Response includes resource location information to the shipment items.
```ruby
shipment = Fulfillment::Shipment.show(@client, @shipment_public_id)`
```

###Fulfillment::Shipment.add(client, order_public_id, shipment_public_id, shipment_item_hashes_array)

Adds items to a shipment.  Limited to 100 items at a time, and returning an error if this limit is exceeded.
The Shipment resource returned will include a location to the order items added as well as the new total number of order items for this order. If quantity\_shorted is not provided it will be defaulted to 0. If quantity\_shipped is not provided it will be defaulted to 1.
```ruby
shipment_item_hashes_array = [
  {
    :public_id => 'FOIfb27e0',
    :quantity_shipped => '2',
    :quantity_shorted => '1'
  },
  {
    :public_id => 'FOI4eeae3'
  }
]
shipment = Fulfillment::Shipment.add(@client, @order.public_id, @shipment.public_id, shipment_item_hashes_array)
```

###Fulfillment::Shipment.close(client, order_public_id, shipment_public_id)

Moves a FulfillmentShipment into the 'closed' state to signify nothing more will be added to the shipment.
```ruby
closed_shipment = Fulfillment::Shipment.close(client, order_public_id, shipment_public_id)
```

###Fulfillment::Shipment.list(client)

List all shipments.  The resource will be a PagedResult of Shipments.
```ruby
shipments = Fulfillment::Shipment.list(client)
```

###Fulfillment::Shipment.shipment_items(client, shipment_public_id)

List items in a shipment.  The resource will be a PagedResult of ShipmentItems.
```ruby
shipment_items = Fulfillment::Shipment.shipment_items(client, shipment_public_id)
```
OR
```ruby
shipment_items = @shipment.shipment_items
```
