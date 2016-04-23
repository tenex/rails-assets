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
    visit '/#/components/foobar-ui?version=1.2.3'

    page.find('select[ng-model="selectedVersion"] option[selected]').text.should eq '1.2.3'
    page.should have_text("gem 'rails-assets-foobar-ui', '1.2.3', source: 'https://rails-assets.org'")
  end

  scenario 'updates the selected version when choosing from the version select box' do
    visit '/#/components/foobar-ui'

    page.find('select[ng-model="selectedVersion"] option:last-child').select_option

    page.current_url.should end_with '/#/components/foobar-ui?version=1.2.3'
    page.should have_text("gem 'rails-assets-foobar-ui', '1.2.3', source: 'https://rails-assets.org'")
  end

  scenario 'navigating back to search preserves the previous search query' do
    raise 'unimplemented'
  end

  scenario 'navigating back to search uses current gem name as query when no previous is present' do
    raise 'unimplemented'
  end

  scenario 'instructions describe a javascript include when the component only contains javascript main assets' do
    raise 'unimplemented'
  end

  scenario 'instructions describe javascript and css includes' do
    raise 'unimplemented'
  end

  scenario 'an appropriate error message is shown when no main assets are found' do
    raise 'unimplemented'
  end
end
