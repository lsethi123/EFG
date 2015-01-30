shared_examples_for "loan change on loan with tranche drawdowns" do
  context "loan with tranche drawdowns" do
    before do
      premium_schedule = loan.premium_schedules.last

      premium_schedule.second_draw_amount = Money.new(10_000_00)
      premium_schedule.second_draw_months = 6

      premium_schedule.third_draw_amount = Money.new(5_000_00)
      premium_schedule.third_draw_months = 12

      premium_schedule.fourth_draw_amount = Money.new(2_000_00)
      premium_schedule.fourth_draw_months = 24

      premium_schedule.save!
    end

    it "retains tranche drawdowns in new premium schedule" do
      dispatch

      loan.reload
      premium_schedule = loan.premium_schedules.last!
      expect(premium_schedule.second_draw_amount).to eq(Money.new(10_000_00))
      expect(premium_schedule.second_draw_months).to eq(6)
      expect(premium_schedule.third_draw_amount).to eq(Money.new(5_000_00))
      expect(premium_schedule.third_draw_months).to eq(12)
      expect(premium_schedule.fourth_draw_amount).to eq(Money.new(2_000_00))
      expect(premium_schedule.fourth_draw_months).to eq(24)
    end
  end
end

shared_examples_for "loan change on loan with capital repayment holiday" do
  context "loan with capital repayment holiday" do
    before do
      premium_schedule = loan.premium_schedules.last
      premium_schedule.initial_capital_repayment_holiday = 6
      premium_schedule.save!
    end

    it "retains capital repayment holiday duration in new premium schedule" do
      dispatch

      loan.reload
      premium_schedule = loan.premium_schedules.last!
      premium_schedule.initial_capital_repayment_holiday = 6
    end
  end
end

shared_examples_for "loan change on loan with no premium schedule" do
  context "loan has no premium schedule" do
    before do
      loan.premium_schedules.destroy_all
      expect(loan.premium_schedules).to be_empty
    end

    it "creates a new premium schedule based on the loan change data" do
      dispatch

      loan.reload
      expect(loan.premium_schedules.count).to eq(1)
    end
  end
end
