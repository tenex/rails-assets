require 'spec_helper'

feature 'Component search' do
  let(:asset_paths) { ['app/assets/javascripts/foobar/foobar-ui.js', 'app/assets/stylesheets/foobar/foobar.css'] }
  let!(:component) { create(:component, name: 'foobar-ui') }
  let!(:old_version) { create(:version, string: '1.2.3', component: component, asset_paths: asset_paths) }
  let!(:latest_version) { create(:version, string: '1.3.2', component: component, asset_paths: asset_paths, main_paths: asset_paths) }

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
    visit root_path
    page.fill_in('gem-search', with: 'foo')
    page.find('a', text: 'Install').click

    click_link 'Back to search results'

    page.find('#gem-search').value.should eq 'foo'
  end

  scenario 'navigating back to search uses current gem name as query when no previous is present' do
    visit '/#/components/foobar-ui'

    click_link 'Back to search results'

    page.find('#gem-search').value.should eq 'foobar-ui'
  end

  scenario 'instructions describe a javascript include when the component only contains javascript main assets' do
    create(:version, string: '4.0.4', component: component, asset_paths: asset_paths,
      main_paths: ['app/assets/javascripts/foobar/foobar-ui.js']
    )

    visit '/#/components/foobar-ui?version=4.0.4'

    page.all('div.instructions > h2').last.text.should end_with 'Include javascript'
    page.should have_text('app/assets/javascripts/application.js')
    page.should_not have_text('app/assets/stylesheets/application.css')
  end

  scenario 'instructions describe a css include when the component only contains css main assets' do
    create(:version, string: '4.0.4', component: component, asset_paths: asset_paths,
      main_paths: ['app/assets/stylesheets/foobar/foobar.css']
    )

    visit '/#/components/foobar-ui?version=4.0.4'

    page.all('div.instructions > h2').last.text.should end_with 'Include stylesheet'
    page.should_not have_text('app/assets/javascripts/application.js')
    page.should have_text('app/assets/stylesheets/application.css')
  end

  scenario 'instructions describe javascript and css includes' do
    visit '/#/components/foobar-ui?version=1.3.2'

    page.all('div.instructions > h2').last.text.should end_with 'Include javascript and stylesheet'
    page.should have_text('app/assets/javascripts/application.js')
    page.should have_text('app/assets/stylesheets/application.css')
  end

  scenario 'an appropriate error message is shown when no main assets are found' do
    raise 'unimplemented' #1.2.3
  end
end
