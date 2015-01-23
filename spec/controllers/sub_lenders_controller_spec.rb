require 'spec_helper'

describe SubLendersController do
  let(:lender) { FactoryGirl.create(:lender) }

  describe 'GET index' do
    def dispatch
      get :index, lender_id: lender.id
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

  describe 'GET new' do
    def dispatch
      get :new, lender_id: lender.id
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

  describe 'POST create' do
    def dispatch
      post :create, lender_id: lender.id
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

  describe 'GET edit' do
    let(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender) }

    def dispatch
      get :edit, lender_id: lender.id, id: sub_lender.id
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

  describe 'PUT update' do
    let(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender) }

    def dispatch
      put :update, { lender_id: lender.id, id: sub_lender.id, sub_lender: { name: 'foo' } }
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

  describe 'DELETE destroy' do
    let(:sub_lender) { FactoryGirl.create(:sub_lender, lender: lender) }

    def dispatch
      delete :destroy, lender_id: lender.id, id: sub_lender.id
    end

    it_behaves_like 'AuditorUser-restricted controller'
    it_behaves_like 'CfeUser-restricted controller'
    it_behaves_like 'LenderAdmin-restricted controller'
    it_behaves_like 'LenderUser-restricted controller'
    it_behaves_like 'PremiumCollectorUser-restricted controller'
  end

end
