require 'spec_helper'

describe DonationsController, type: :controller do
  describe '#create' do
    let(:token) do
      Stripe::Token.create(
        card: {
          number: 4_242_424_242_424_242,
          exp_month: 12,
          exp_year: Time.now.year+1,
          cvc: 123
        }
      ).to_h.merge(email: 'test@example.com') # simulate stripe checkout request
    end

    it 'creates a charge for the given amount' do
      VCR.use_cassette 'stripe' do
        post :create, amount: '$5.45', token: token
      end

      response.should be_success
      assigns(:charge).status.should eq 'succeeded'
      assigns(:charge).amount.should eq 545
    end

    it 'returns an error if the amount cannot be parsed' do
      VCR.use_cassette 'stripe' do
        post :create, amount: 'balls', token: token
      end

      response.should be_client_error
      JSON.parse(response.body)['error'].should include 'Please enter a valid amount'
    end

    let(:token_decline_always) do
      Stripe::Token.create(
        card: {
          number: 4_000_000_000_000_002,
          exp_month: 12,
          exp_year: Time.now.year+1,
          cvc: 123
        }
      )
    end

    it 'returns an error if stripe returns one' do
      VCR.use_cassette 'stripe' do
        post :create, amount: '$1.23', token: token_decline_always.to_h
      end

      response.should be_client_error
      JSON.parse(response.body)['error'].should include 'declined'
    end
  end
end
