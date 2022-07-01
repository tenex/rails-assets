require 'spec_helper'

feature 'Stripe integreation' do
  scenario 'accepts donations' do
    visit root_path

    page.find(:css, 'nav div', text: 'Donate').click

    fill_in 'amount', with: '5.45'
    click_button 'Next'

    Capybara.within_frame 'stripe_checkout_app' do
      fill_in 'Email', with: 'rspec@example.com'
      # the next bit *would* be:
      # fill_in 'Card number', with: '4242 4242 4242 4242'
      # except that the result is that card_number becomes
      # 4242 (actually a random subset of above)
      card_number_field = page.find_by_id('card_number')
      '4242424242424242'.chars.each do |digit|
        card_number_field.send_keys digit
        sleep 0.1
      end

      # fill_in 'MM / YY', with: 1.year.from_now.strftime('%m/%y')
      cc_exp_field = page.find_by_id 'cc-exp'
      1.year.from_now.strftime('%m/%y').chars.each do |char|
        cc_exp_field.send_keys char
        sleep 0.1
      end
      fill_in 'CVC', with: '322'
      click_button 'Pay $5.45'
    end

    page.should_not have_css('iframe.stripe_checkout_app', wait: 30)
    page.should have_text('Thank you for your donation!')
  end
end
