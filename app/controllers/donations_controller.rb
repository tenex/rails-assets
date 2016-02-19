class DonationsController < ApplicationController
  def create
    @amount = params[:amount]
    @amount = @amount.remove(/[$,]/) if @amount.respond_to?(:remove)

    begin
      @amount = Float(@amount).round(2)
    rescue
      render json: { error: 'Donation failed. Please enter a valid amount in USD ($).' }, status: :unprocessable_entity
      return
    end

    @amount = (@amount * 100).to_i # Must be an integer!

    @charge = Stripe::Charge.create(
      amount: @amount,
      currency: 'usd',
      source: params[:token][:id],
      description: 'Rails Assets donation'
    )

    render nothing: true, status: :no_content
  rescue Stripe::CardError => e
    render json: { error: "Donation failed. #{e.message}" }, status: :unprocessable_entity
  end
end
