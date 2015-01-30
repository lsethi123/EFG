require 'spec_helper'

describe DedCode do

  describe "validations" do
    let(:ded_code) { FactoryGirl.build(:ded_code) }

    it "should have a valid factory" do
      expect(ded_code).to be_valid
    end

    it "must have a group_description" do
      ded_code.group_description = nil
      expect(ded_code).not_to be_valid
    end

    it "must have a category_description" do
      ded_code.category_description = nil
      expect(ded_code).not_to be_valid
    end

    it "must have a code" do
      ded_code.code = nil
      expect(ded_code).not_to be_valid
    end

    it "must have a code_description" do
      ded_code.code_description = nil
      expect(ded_code).not_to be_valid
    end
  end

end
