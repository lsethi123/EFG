require 'spec_helper'

describe SettleLoan do

  describe "validations" do
    let(:loan) { FactoryGirl.create(:loan, :demanded) }
    let(:presenter) { SettleLoan.new(loan) }

    it "must have a settled_amount" do
      presenter.settled_amount = nil
      expect(presenter).not_to be_valid
    end

    it "must have a settled_amount greater than or equal to 0" do
      presenter.settled_amount = Money.new(-1)
      expect(presenter).not_to be_valid

      presenter.settled_amount = Money.new(0)
      expect(presenter).to be_valid
    end

    it "must have a settled_amount less than or equal to the claimed amount" do
      loan.dti_amount_claimed = Money.new(4824_95)

      presenter.settled_amount = Money.new(4824_96)
      expect(presenter).not_to be_valid

      presenter.settled_amount = Money.new(4824_95)
      expect(presenter).to be_valid
    end
  end

  describe "attributes" do
    let(:loan) { FactoryGirl.build(:loan, :demanded) }
    let(:presenter) { SettleLoan.new(loan) }

    it "delegates id" do
      expect(presenter.id).to eq(loan.id)
    end

    it "delegates business name" do
      expect(presenter.business_name).to eq(loan.business_name)
    end

    it "delegates corrected?" do
      expect(presenter.corrected?).to eq(loan.corrected?)
    end

    it "delegates dti_amount_claimed" do
      expect(presenter.dti_amount_claimed).to eq(loan.dti_amount_claimed)
    end

    it "delegates dti_demanded_on" do
      expect(presenter.dti_demanded_on).to eq(loan.dti_demanded_on)
    end

    it "delegates reference" do
      expect(presenter.reference).to eq(loan.reference)
    end
  end

  describe "#settled?" do
    let(:loan) { FactoryGirl.build(:loan, :demanded) }
    let(:presenter) { SettleLoan.new(loan) }

    it "is false by default" do
      expect(presenter).not_to be_settled
    end

    it "can be set" do
      presenter.settled = true
      expect(presenter).to be_settled
    end
  end

  describe "#settled_amount" do
    let(:loan) { FactoryGirl.build(:loan, :demanded, dti_amount_claimed: Money.new(15_594_80)) }
    let(:presenter) { SettleLoan.new(loan) }

    it "defaults to the dti_claimed_amount" do
      expect(presenter.settled_amount).to eq(Money.new(15_594_80))
    end

    it "can be set" do
      presenter.settled_amount = '10,000.00'
      expect(presenter.settled_amount).to eq(Money.new(10_000_00))
    end
  end

  describe "settle!" do
    let(:creator) { FactoryGirl.create(:user) }
    let(:invoice) { FactoryGirl.create(:invoice) }
    let(:loan) { FactoryGirl.create(:loan, :demanded) }

    context "marked as settled" do
      let(:presenter) do
        presenter = SettleLoan.new(loan)
        presenter.settled = true
        presenter.settled_amount = Money.new(340_12)
        presenter
      end

      it "transitions the loan to Settled" do
        Timecop.freeze(2013, 1, 22, 11, 49) do
          presenter.settled = true
          presenter.settle!(invoice, creator)

          loan.reload

          expect(loan.state).to eq(Loan::Settled)
          expect(loan.settled_on).to eq(Date.new(2013, 1, 22))
          expect(loan.invoice).to eq(invoice)
          expect(loan.updated_at).to eq(Time.new(2013, 1, 22, 11, 49, 0))
          expect(loan.modified_by_id).to eq(creator.id)
        end
      end

      it "updates the settled amount" do
        presenter.settle!(invoice, creator)

        loan.reload
        expect(loan.settled_amount).to eq(Money.new(340_12))
      end

      it "logs the loan state changes" do
        expect {
          presenter.settle!(invoice, creator)
        }.to change(LoanStateChange, :count).by(1)
      end
    end

    context "not marked as settled" do
      let(:presenter) do
        presenter = SettleLoan.new(loan)
        presenter.settled = false
        presenter
      end

      it "raises an NotMarkedAsSettled exception" do
        expect(presenter).not_to be_settled
        expect {
          presenter.settle!(invoice, creator)
        }.to raise_error(SettleLoan::NotMarkedAsSettled)
      end
    end
  end
end
