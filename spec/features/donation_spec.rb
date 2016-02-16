require 'spec_helper'

feature 'Stripe integreation' do
  scenario 'accepts donations' do
    visit root_path

    click_link 'Donate'

    fill_in 'amount', with: '5.45'
    click_button 'Next'

    Capybara.within_frame 'stripe_checkout_app' do
      fill_in 'email', with: 'rspec@example.com'
      page.execute_script(%Q{ $('input#card_number').val('4242 4242 4242 4242'); })
      page.execute_script(%Q{ $('input#cc-exp').val('#{1.year.from_now.strftime('%m/%y')}'); })
      fill_in 'cc-csc', with: '322'
      click_button 'Pay $5.45'
    end

    page.should_not have_css('iframe.stripe_checkout_app', wait: 6)
    page.should have_text('Thank you for your donation!')
  end
end
