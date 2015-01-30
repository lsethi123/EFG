# encoding: utf-8

require 'spec_helper'

describe DataCorrection do
  it_behaves_like 'LoanModification'

  describe '#seq' do
    let(:loan) { FactoryGirl.create(:loan, :guaranteed) }

    it 'is incremented for each DataCorrection' do
      correction1 = FactoryGirl.create(:data_correction, loan: loan)
      correction2 = FactoryGirl.create(:data_correction, loan: loan)

      expect(correction1.seq).to eq(1)
      expect(correction2.seq).to eq(2)
    end
  end

  describe "#changes" do
    describe "data correction with lending limit change" do
      it "should return the old and new lending limits" do
        lender = FactoryGirl.create(:lender)
        lending_limit_1 = FactoryGirl.create(:lending_limit, lender: lender)
        lending_limit_2 = FactoryGirl.create(:lending_limit, lender: lender)

        data_correction = FactoryGirl.create(:data_correction, old_lending_limit_id: lending_limit_1.id, lending_limit_id: lending_limit_2.id)
        expect(data_correction.changes).to eq([{
          old_attribute: 'old_lending_limit',
          old_value: lending_limit_1,
          attribute: 'lending_limit',
          value: lending_limit_2
        }])
      end
    end
  end
end
