require 'spec_helper'

feature 'Stripe integreation' do
  scenario 'accepts donations' do
    visit root_path

    page.find(:css, 'nav div', text: 'Donate').click

    fill_in 'amount', with: '5.45'
    click_button 'Next'

    Capybara.within_frame 'stripe_checkout_app' do
      fill_in 'Email', with: 'rspec@example.com'
      fill_in 'Card number', with: '4242 4242 4242 4242'
      fill_in 'Expiry', with: 1.year.from_now.strftime('%m/%y')
      fill_in 'CVC', with: '322'
      click_button 'Pay $5.45'
    end

    page.should_not have_css('iframe.stripe_checkout_app', wait: 30)
    page.should have_text('Thank you for your donation!')
  end
end
