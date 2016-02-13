require 'spec_helper'

feature 'Stripe integreation' do
  scenario 'accepts donations' do
    visit root_path
    click_button 'Donate'
    fill_in 'Amount', with: '5.00'

    fill_in 'email', with: 'rspec@example.com'
    fill_in 'credit card', with: '4242 4242 4242 4242'
    fill_in 'cvv', with: '322'
    fill_in 'expiration', with: 'whatever'

    raise 'shit'
  end
end
