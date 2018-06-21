date_format = "%m/%d/%Y %H:%M"

def address(xml, address, type, order)
  name    = "#{type.to_s.titleize}To"

  xml.__send__(name) {
    xml.Name       trim_field(address.full_name, 100)
    xml.Company    trim_field(address.company, 100)

    if type == :ship
      xml.Address1   trim_field(address.address1, 200)
      xml.Address2   trim_field(address.address2, 200)
      xml.City       trim_field(address.city, 100)
      xml.State      address.state ? address.state.abbr : address.state_name
      xml.PostalCode address.zipcode
      xml.Country    address.country.iso
    end

    xml.Phone        trim_field(address.phone, 50)
    if type == :bill
      xml.Email      trim_field(order.email, 100)
    end
  }
end

def trim_field(value, length)
  (value || "").slice(0, length)
end

xml.instruct!
xml.Orders(pages: (@shipments.total_count/20.0).ceil) {
  @shipments.each do |shipment|
    order = shipment.order

    xml.Order {
      xml.OrderID        shipment.id
      xml.OrderNumber    Spree::Config.shipstation_number == :order ? order.number : shipment.number
      xml.OrderDate      (order.completed_at || order.created_at).utc.strftime(date_format)
      xml.OrderStatus    shipment.state
      xml.LastModified   [order.completed_at, shipment.updated_at].max.utc.strftime(date_format)
      xml.ShippingMethod shipment.shipping_method.try(:name)
      xml.OrderTotal     order.total
      xml.TaxAmount      order.additional_tax_total
      xml.ShippingAmount order.shipment_total

      if order.respond_to? :shipstation_custom_field_1
        xml.CustomField1   trim_field(order.shipstation_custom_field_1, 100)
      else
        xml.CustomField1   order.number
      end

      if order.respond_to? :shipstation_custom_field_2
        xml.CustomField2   trim_field(order.shipstation_custom_field_2, 100)
      end

      if order.respond_to? :shipstation_custom_field_3
        xml.CustomField3   trim_field(order.shipstation_custom_field_3, 100)
      end

      if order.respond_to?(:gift?)
        xml.Gift order.gift?
        xml.GiftMessage trim_field(order.gift_wrapping_message, 1000)
      end

      unless order.special_instructions.blank?
        xml.CustomerNotes trim_field(order.special_instructions, 1000)
      end

      xml.Customer {
        xml.CustomerCode trim_field(order.email, 50)
        address(xml, order.bill_address, :bill, order)
        if shipment.respond_to?(:alternate_ship_address) && shipment.alternate_ship_address
          address(xml, shipment.alternate_ship_address, :ship, order)
        else
          address(xml, order.ship_address, :ship, order)
        end
      }
      xml.Items {
        shipment.variants_hash_for_export.each_pair do |variant, quantity_and_price|
          xml.Item {
            xml.SKU         variant.sku
            xml.Name        trim_field([variant.product.name, variant.options_text].join(' '), 200)
            xml.ImageUrl    variant.images.first.try(:attachment).try(:url)
            xml.Weight      variant.weight.to_f
            xml.WeightUnits Spree::Config.shipstation_weight_units
            xml.Quantity    quantity_and_price[:quantity]
            xml.UnitPrice   quantity_and_price[:price].round(2)
            xml.Location    variant.try(:stock_items).first.try(:shelf_location) || ""

            if variant.option_values.present?
              xml.Options {
                variant.option_values.each do |value|
                  xml.Option {
                    xml.Name  value.option_type.presentation
                    xml.Value value.option_type.presentation == "Color" ? value.presentation : value.name
                  }
                end
              }
            end
          }
        end
        if order.respond_to?(:shipstation_bonus_items)
          order.shipstation_bonus_items(shipment).each do |item|
            xml.Item {
              xml.SKU         item[:sku]
              xml.Name        trim_field(item[:name], 200)
              xml.ImageUrl    item[:image_url]
              xml.Weight      item[:weight]
              xml.WeightUnits Spree::Config.shipstation_weight_units
              xml.Quantity    item[:quantity]
              xml.UnitPrice   item[:price].round(2)
              xml.Location    item[:location] || ''
            }
          end
        end
      }
    }
  end
}
