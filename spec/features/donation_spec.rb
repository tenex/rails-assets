require 'spec_helper'

feature 'Stripe integreation' do
  scenario 'accepts donations' do
    visit root_path
    fill_in 'amount', with: '5.45'
    click_button 'Donate'

    fill_in 'email', with: 'rspec@example.com'
    fill_in 'card_number', with: '4242424242424242'
    fill_in 'cc-exp', with: 1.year.from_now.strftime('%m/%y')
    fill_in 'cc-csc', with: '322'

    click_button 'Pay $5.45'
    
    raise 'WIP'
  end
end
