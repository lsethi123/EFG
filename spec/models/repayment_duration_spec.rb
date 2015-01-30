require 'spec_helper'

describe RepaymentDuration do

  let(:repayment_duration) { RepaymentDuration.new(loan) }

  context 'with loan category' do
    context 'and non-transferred loan' do
      let(:loan) { FactoryGirl.build(:loan, loan_category_id: LoanCategory::TypeE.id) }

      describe '#min_months' do
        it "should return minimum number of loans months based on loan category minimum term months" do
          expect(repayment_duration.min_months).to eq(3)
        end
      end

      describe '#max_months' do
        it "should return maximum number of loans months based on loan category minimum term months" do
          expect(repayment_duration.max_months).to eq(24)
        end
      end
    end
  end

  context 'without loan category' do
    context 'and SFLG loan' do
      let(:loan) { FactoryGirl.build(:loan, :sflg, loan_category_id: nil) }

      context 'without loan category' do
        describe '#min_months' do
          it "should return default minimum number of loans months for SFLG loan" do
            expect(repayment_duration.min_months).to eq(24)
          end
        end

        describe '#max_months' do
          it "should return default maximum number of loans months for SFLG loan" do
            expect(repayment_duration.max_months).to eq(120)
          end
        end
      end
    end

    context 'and EFG loan' do
      let(:loan) { FactoryGirl.build(:loan, loan_category_id: nil) }

      context 'without loan category' do
        describe '#min_months' do
          it "should return default minimum number of loans months for EFG loan" do
            expect(repayment_duration.min_months).to eq(3)
          end
        end

        describe '#max_months' do
          it "should return default maximum number of loans months for SFLG loan" do
            expect(repayment_duration.max_months).to eq(120)
          end
        end
      end
    end
  end

  context 'with transferred loan' do
    let(:loan) { FactoryGirl.build(:loan, :transferred) }

    describe '#min_months' do
      it "should return 0 transferred loans have no start date limit" do
        expect(repayment_duration.min_months).to eq(0)
      end
    end

    describe '#max_months' do
      it "should return default maximum number of loans months for EFG loan" do
        expect(repayment_duration.max_months).to eq(120)
      end
    end
  end

  describe "#months_between_draw_date_and_maturity_date" do

    context 'with loan term of several years' do
      let!(:loan) { FactoryGirl.create(:loan, :guaranteed, maturity_date: Date.new(2020, 3, 1)) }

      before do
        loan.initial_draw_change.update_attribute(:date_of_change, Date.new(2012, 2, 29))
      end

      it "should return the number of months from the initial draw date to the maturity date" do
        expect(repayment_duration.months_between_draw_date_and_maturity_date).to eql(97)
      end
    end

    context 'with loan term of one year' do
      let!(:loan) { FactoryGirl.create(:loan, :guaranteed, maturity_date: Date.new(2013, 1, 31)) }

      before do
        loan.initial_draw_change.update_attribute(:date_of_change, Date.new(2012, 1, 31))
      end

      it "should return the number of months from the initial draw date to the maturity date" do
        expect(repayment_duration.months_between_draw_date_and_maturity_date).to eql(12)
      end
    end

    context 'with loan term of one year, 1 day' do
      let!(:loan) { FactoryGirl.create(:loan, :guaranteed, maturity_date: Date.new(2013, 2, 1)) }

      before do
        loan.initial_draw_change.update_attribute(:date_of_change, Date.new(2012, 1, 31))
      end

      it "should return the number of months from the initial draw date to the maturity date" do
        expect(repayment_duration.months_between_draw_date_and_maturity_date).to eql(13)
      end
    end

    context 'with loan term of 364 days' do
      let!(:loan) { FactoryGirl.create(:loan, :guaranteed, maturity_date: Date.new(2013, 1, 19)) }

      before do
        loan.initial_draw_change.update_attribute(:date_of_change, Date.new(2012, 1, 20))
      end

      it "should return the number of months from the initial draw date to the maturity date" do
        expect(repayment_duration.months_between_draw_date_and_maturity_date).to eql(12)
      end
    end
  end

end
