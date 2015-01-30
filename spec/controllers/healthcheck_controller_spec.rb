require 'spec_helper'

describe HealthcheckController do
  describe "#index" do
    it "should return success" do
      get :index
      expect(response).to be_success
    end

    it "should fail when the database isn't available" do
      Lender.stub(:count).and_raise(Mysql2::Error.new("Database unavailable"))

      expect {
        get :index
      }.to raise_error(Mysql2::Error)
    end
  end
end
