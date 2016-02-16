class DonationsController < ApplicationController
  after_filter :log_donation, only: :create

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

  private

  def log_donation
    Donation.create!(
      amount: @amount,
      email: params[:token][:email],
      client_ip: params[:token][:client_ip]
    )
  rescue => ex
    Rails.logger.error "Failed to log donation: #{ex.message}"
    Rails.logger.error ex.backtrace.join("\n")
  end
end
