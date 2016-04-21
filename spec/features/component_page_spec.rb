require 'spec_helper'

feature 'Component search' do
  let!(:component) { create(:component, name: 'foobar-ui') }
  let!(:old_version) { create(:version, string: '1.2.3', component: component )}
  let!(:latest_version) { create(:version, string: '1.3.2', component: component )}

  scenario 'supports direct navigation to the component, which automatically selects the latest version' do
    visit '/#/components/foobar-ui'

    page.find('select[ng-model="selectedVersion"] option[selected]').text.should eq '1.3.2'
    page.should have_text("gem 'rails-assets-foobar-ui', source: 'https://rails-assets.org'")
  end

  scenario 'supports direct navigation to component versions' do
    visit '/#/components/foobar-ui/1.2.3'

    page.find('select[ng-model="selectedVersion"] option[selected]').text.should eq '1.2.3'
    page.should have_text("gem 'rails-assets-foobar-ui', '1.2.3', source: 'https://rails-assets.org'")
  end

  scenario 'updates the selected version when choosing from the version select box' do
    visit '/#/components/foobar-ui'

    page.find('select[ng-model="selectedVersion"] option:last-child').select_option

    page.current_url.should match '/#/components/foobar-ui/1.2.3'
    page.should have_text("gem 'rails-assets-foobar-ui', '1.2.3', source: 'https://rails-assets.org'")
  end
end

#back to search with gem name
#back to search with previous search
#javascript for js only
#javascript and stylesheet for both
#error message for neither present
