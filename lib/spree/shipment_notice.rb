module Spree
  class ShipmentNotice
    attr_reader :error

    def initialize(params)
      @number   = params[:order_number]
      @tracking = params[:tracking_number]
    end

    def apply
      locate ? update : not_found
    rescue => e
      handle_error(e)
    end

  private
    def locate
      if Spree::Config.shipstation_number == :order
        order = Spree::Order.find_by_number(@number)
        @shipment = order.try(:shipment)
      else
        @shipment = Spree::Shipment.find_by_number(@number)
      end
    end

    def update
      @shipment.update_attribute(:tracking, @tracking)

      unless @shipment.shipped?
        @shipment.reload.update_attribute(:state, 'shipped')
        @shipment.inventory_units.each &:ship!
        @shipment.touch :shipped_at

        # Delay sending customers the shipment notification email for 4 hours.
        # Previously, this delay was set up in the ShipStation system, the HTTP POST
        # notification to /shipnotify was delayed by 4 hours.
        Spree::ShipmentMailer.shipped_email(@shipment.id).deliver_later(wait: 4.hours) if Spree::Config.send_shipped_email

        # TODO: state machine is bypassed above...is there a good reason?
        @shipment.trigger_on_shipped if @shipment.respond_to? :trigger_on_shipped
      end

      true
    end

    def not_found
      @error = I18n.t(:shipment_not_found, number: @number)
      false
    end

    def handle_error(error)
      Rails.logger.error(error)
      @error = I18n.t(:import_tracking_error, error: error.to_s)
      false
    end
  end
end
