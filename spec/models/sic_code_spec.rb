require 'spec_helper'

describe SicCode do

  describe "validations" do
    let(:sic_code) { FactoryGirl.build(:sic_code) }

    it 'has a valid Factory' do
      expect(sic_code).to be_valid
    end

    describe "#code" do
      let(:another_sic_code) { FactoryGirl.build(:sic_code, code: sic_code.code) }

      it 'cannot be blank' do
        sic_code.code = nil
        expect(sic_code).not_to be_valid
      end

      it 'must be unique' do
        sic_code.save
        expect(another_sic_code).not_to be_valid
      end
    end

    it 'requires a description' do
      sic_code.description = nil
      expect(sic_code).not_to be_valid
    end

    it 'requires eligible' do
      sic_code.eligible = nil
      expect(sic_code).not_to be_valid
    end

    it 'requires public_sector_restricted' do
      sic_code.public_sector_restricted = nil
      expect(sic_code).not_to be_valid
    end
  end

end
