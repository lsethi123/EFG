require 'spec_helper'

describe 'Claim limits report' do

  before(:each) do
    login_as(current_user, scope: :user)
  end

  context "as a Cfe User" do
    let!(:current_user) { FactoryGirl.create(:cfe_user) }

    it "should output a CSV report" do
      visit root_path
      click_link 'Generate Claim Limits Report'

      expect(page.response_headers['Content-Type']).to include('text/csv')
    end
  end

end
