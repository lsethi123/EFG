require 'spec_helper'

describe UserAudit do

  describe "validations" do
    let(:user_audit) { FactoryGirl.build(:user_audit) }

    it "should have a valid factory" do
      expect(user_audit).to be_valid
    end

    it "must have a user_id" do
      user_audit.user_id = nil
      expect(user_audit).not_to be_valid
    end

    it "must have a function" do
      user_audit.function = nil
      expect(user_audit).not_to be_valid
    end

    it "must have a modified_by_id" do
      user_audit.modified_by_id = nil
      expect(user_audit).not_to be_valid
    end

    it "must have a password" do
      user_audit.password = nil
      expect(user_audit).not_to be_valid
    end
  end

end
