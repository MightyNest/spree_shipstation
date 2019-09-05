include SpreeShipstation

module Spree
  class ShipstationController < Spree::BaseController
    #include BasicSslAuthentication
    include Spree::DateParamHelper

    skip_before_filter :verify_authenticity_token
    before_filter :authenticate

    def authenticate
      authenticate_or_request_with_http_basic('Authentication Required') do |username, password|
        username == Spree::Config.shipstation_username && password == Spree::Config.shipstation_password
      end
    end

    layout false

    def export
      @page_size = Spree::Config.shipstation_page_size
      @shipments = Spree::Shipment.exportable.between(date_param(:start_date), date_param(:end_date)).page(params[:page]).per(@page_size)
    end

    def shipnotify
      @notice = notice = Spree::ShipmentNotice.new(params)

      number = params[:order_number]
      shipment = Spree::Shipment.find_by_number(number)
      if shipment
        order = shipment.order
        order.shipment_state = 'shipped'
        order.save!
      end

      if notice.apply
        @text = 'success'
        respond_to do |format|
          format.html { render(text: @text, status: :ok) }
          format.xml { render template: "spree/shipstation/shipnotify", status: :ok }
          format.json { render json: {text: @text, status: :ok} }
        end
      else
        @text = notice.error
        respond_to do |format|
          format.html { render(@text, status: :bad_request) }
          format.xml { render template: "spree/shipstation/shipnotify", status: :bad_request }
          format.json { render json: {text: @text, status: :bad_request} }
        end
      end
    end
  end
end
