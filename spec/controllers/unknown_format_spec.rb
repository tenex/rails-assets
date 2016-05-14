require 'spec_helper'

feature 'Unexpected request formats' do
  controller do
    def index
      respond_to do |format|
        format.html { render nothing: true }
      end
    end
  end

  scenario 'accepted content-type matches exceptations' do
    get :index

    response.should be_success
  end

  scenario 'content-type format does not match expectations' do
    get :index, format: :json

    response.status.should eq 406
  end
end
