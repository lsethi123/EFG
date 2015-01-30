require 'spec_helper'

describe LendingLimit do

  describe 'validations' do
    let(:lending_limit) { FactoryGirl.build(:lending_limit) }

    it 'has a valid Factory' do
      expect(lending_limit).to be_valid
    end

    it 'strictly requires a lender' do
      expect {
        lending_limit.lender = nil
        lending_limit.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed) 
    end

    it 'requires an allocation' do
      lending_limit.allocation = nil
      expect(lending_limit).not_to be_valid
    end

    it 'requires a starts_on date' do
      lending_limit.starts_on = nil
      expect(lending_limit).not_to be_valid
    end

    it 'requires a ends_on date' do
      lending_limit.ends_on = nil
      expect(lending_limit).not_to be_valid
    end

    it 'requires a valid allocation_type_id' do
      lending_limit.allocation_type_id = ''
      expect(lending_limit).not_to be_valid
      lending_limit.allocation_type_id = '99'
      expect(lending_limit).not_to be_valid
      lending_limit.allocation_type_id = '1'
      expect(lending_limit).to be_valid
    end

    it 'requires a name' do
      lending_limit.name = ''
      expect(lending_limit).not_to be_valid
    end

    it 'requires ends_on to be after starts_on' do
      lending_limit.starts_on = Date.new(2012, 1, 2)
      lending_limit.ends_on = Date.new(2012, 1, 1)
      expect(lending_limit).not_to be_valid
    end
  end

  it "has many loans using allocation" do
    lending_limit = FactoryGirl.create(:lending_limit)

    expected_loans = LendingLimit::USAGE_LOAN_STATES.collect do |state|
      FactoryGirl.create(:loan, state: state, lending_limit: lending_limit)
    end

    eligible_loan = FactoryGirl.create(:loan, :eligible, lending_limit: lending_limit)

    expect(lending_limit.loans_using_lending_limit).to eq(expected_loans)
  end

  describe "activation" do
    context "with an active lending limit" do
      let(:lending_limit) { FactoryGirl.create(:lending_limit, :active) }

      specify "#activate! doesn't change active flag" do
        lending_limit.activate!
        lending_limit.reload

        expect(lending_limit).to be_active
      end

      specify "#deactivate! sets the active flag to false" do
        lending_limit.deactivate!
        lending_limit.reload

        expect(lending_limit).not_to be_active
      end
    end

    context "with an inactive lending limit" do
      let(:lending_limit) { FactoryGirl.create(:lending_limit, :inactive) }

      specify "#activate! sets the active flag to true" do
        lending_limit.activate!
        lending_limit.reload

        expect(lending_limit).to be_active
      end

      specify "#deactivate! sets the active flag to false" do
        lending_limit.deactivate!
        lending_limit.reload

        expect(lending_limit).not_to be_active
      end
    end
  end

  describe ".current" do
    it "filters lending limits that are start on or before the current date, and end after the " do
      ended_in_past = FactoryGirl.create(:lending_limit, starts_on: 4.weeks.ago, ends_on: 2.weeks.ago)
      ends_today = FactoryGirl.create(:lending_limit, starts_on: 4.weeks.ago, ends_on: Date.current)
      overlaps_today = FactoryGirl.create(:lending_limit, starts_on: 2.weeks.ago, ends_on: 2.weeks.from_now)
      starts_today = FactoryGirl.create(:lending_limit, starts_on: Date.current, ends_on: 4.weeks.from_now)
      starts_in_future = FactoryGirl.create(:lending_limit, starts_on: 2.weeks.from_now, ends_on: 4.weeks.from_now)

      expect(LendingLimit.current).to match_array([ends_today, overlaps_today, starts_today])
    end
  end

  describe "#unavailable?" do
    it "unavailable if its not current and past the 30 day grace period" do
      lending_limit = FactoryGirl.build(:lending_limit, :active, starts_on: 4.weeks.ago, ends_on: 6.weeks.ago)
      expect(lending_limit).to be_unavailable
    end

    it "available if its not current and within the 30 day grace period" do
      lending_limit = FactoryGirl.build(:lending_limit, :active, starts_on: 4.weeks.ago, ends_on: 30.days.ago)
      expect(lending_limit).not_to be_unavailable
    end

    it "unavailable if its not active" do
      lending_limit = FactoryGirl.build(:lending_limit, :inactive, starts_on: 4.weeks.ago, ends_on: 4.weeks.from_now)
      expect(lending_limit).to be_unavailable
    end

    it "available if its active and current" do
      lending_limit = FactoryGirl.build(:lending_limit, :active, starts_on: 4.weeks.ago, ends_on: 4.weeks.from_now)
      expect(lending_limit).not_to be_unavailable
    end
  end
end
