class DonationsController < ApplicationController
  def create
    @amount = params[:amount]

    @amount = @amount.gsub('$', '').gsub(',', '') if @amount.respond_to? :gsub

    begin
      @amount = Float(@amount).round(2)
    rescue
      flash[:error] = 'Charge not completed. Please enter a valid amount in USD ($).'
      redirect_to new_charge_path
      return
    end

    @amount = (@amount * 100).to_i # Must be an integer!

    Stripe::Charge.create(
      :amount => @amount,
      :currency => 'usd',
      :source => params[:token][:id],
      :description => 'Rails Assets donation'
    )

    render nothing: true, status: :no_content

  rescue Stripe::CardError => e
    flash[:error] = e.message
    redirect_to new_charge_path
  end
end
