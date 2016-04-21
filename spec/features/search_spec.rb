require 'spec_helper'

feature 'Component search' do
  let!(:version) { create(:version, component: create(:component, name: 'foobar-ui')) }

  scenario 'link to your search results' do
    visit root_path

    fill_in('gem-search', with: 'foobar')

    page.current_url.should match(/query=foobar$/)
  end

  scenario 'navigate to component page' do
    visit root_path

    page.fill_in('gem-search', with: 'foobar')

    page.find('a', text: 'Install').click

    page.should have_content('Add foobar-ui to your Gemfile')
    page.current_url.should match(/components\/foobar-ui$/)
  end
end
