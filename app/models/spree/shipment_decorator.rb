Spree::Shipment.class_eval do
  scope :exportable, -> {
	joins(:order).where('spree_shipments.state != ?', 'pending').where("#{Spree::Order.table_name}.number not ilike 'D%'")
  }

  def self.between(from, to)
    joins(:order).where('(spree_shipments.updated_at > ? AND spree_shipments.updated_at < ?) OR (spree_orders.updated_at > ? AND spree_orders.updated_at < ?)',from, to, from, to)
  end

end
