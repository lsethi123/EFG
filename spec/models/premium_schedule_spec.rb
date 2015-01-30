require 'spec_helper'

shared_examples_for 'a draw amount validator' do
  before do
    subject.initial_draw_amount = Money.new(5_000_00)
    subject.second_draw_amount  = Money.new(1_000_00)
    subject.second_draw_months  = 1
    subject.third_draw_amount   = Money.new(1_000_00)
    subject.third_draw_months   = 2
    subject.fourth_draw_amount  = Money.new(1_000_00)
    subject.fourth_draw_months  = 3
  end

  context 'when the total of all draw amounts is equal to the loan amount' do
    context 'and there are no nil draw amounts' do
      before { loan.amount = Money.new(8_000_00) }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'and there are nil draw amounts' do
      before do
        loan.amount = Money.new(7_000_00)
        subject.fourth_draw_amount = nil
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  context 'when the total of all draw amounts is less than the loan amount' do
    before { loan.amount = Money.new(10_000_00) }

    context 'and there are no nil draw amounts' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'and there are nil draw amounts' do
      before { subject.fourth_draw_amount = nil }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  context 'when the total of all draw amounts is greater than the loan amount' do
    before { loan.amount = Money.new(5_000_00) }

    context 'and there are no nil draw amounts' do
      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'and there are nil draw amounts' do
      before { subject.fourth_draw_amount = nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end
  end
end

describe PremiumSchedule do

  let(:loan) { premium_schedule.loan }
  let(:premium_schedule) { FactoryGirl.build(:premium_schedule) }

  describe 'validations' do

    it 'has a valid Factory' do
      expect(premium_schedule).to be_valid
    end

    it 'strictly requires a loan' do
      expect {
        premium_schedule.loan = nil
        premium_schedule.valid?
      }.to raise_error(ActiveModel::StrictValidationFailed)
    end

    %w(
      initial_draw_year
      initial_draw_amount
      repayment_duration
    ).each do |attr|
      it "is invalid without #{attr}" do
        premium_schedule.send("#{attr}=", '')
        expect(premium_schedule).not_to be_valid
      end
    end

    it 'requires initial draw amount to be more than zero' do
      premium_schedule.initial_draw_amount = 0
      expect(premium_schedule).not_to be_valid

      premium_schedule.initial_draw_amount = 1
      expect(premium_schedule).to be_valid
    end

    it 'requires initial draw amount to be less than 9,999,999.99' do
      loan.amount = PremiumSchedule::MAX_INITIAL_DRAW

      premium_schedule.initial_draw_amount = PremiumSchedule::MAX_INITIAL_DRAW + Money.new(1)
      expect(premium_schedule).not_to be_valid

      premium_schedule.initial_draw_amount = PremiumSchedule::MAX_INITIAL_DRAW
      expect(premium_schedule).to be_valid
    end

    it 'requires an allowed calculation type' do
      premium_schedule.calc_type = nil
      expect(premium_schedule).not_to be_valid

      premium_schedule.calc_type = "Z"
      expect(premium_schedule).not_to be_valid

      premium_schedule.calc_type = PremiumSchedule::SCHEDULE_TYPE
      expect(premium_schedule).to be_valid

      premium_schedule.calc_type = PremiumSchedule::NOTIFIED_AID_TYPE
      expect(premium_schedule).to be_valid
    end

    %w(
      initial_capital_repayment_holiday
      second_draw_months
      third_draw_months
      fourth_draw_months
    ).each do |attr|
      it "does not require #{attr} if not set" do
        premium_schedule.initial_capital_repayment_holiday = nil
        expect(premium_schedule).to be_valid
      end

      it "requires #{attr} to be 0 or greater if set" do
        premium_schedule.initial_capital_repayment_holiday = -1
        expect(premium_schedule).not_to be_valid
        premium_schedule.initial_capital_repayment_holiday = 0
        expect(premium_schedule).to be_valid
      end

      it "requires #{attr} to be 120 or less if set" do
        premium_schedule.initial_capital_repayment_holiday = 121
        expect(premium_schedule).not_to be_valid
        premium_schedule.initial_capital_repayment_holiday = 120
        expect(premium_schedule).to be_valid
      end
    end

    it_should_behave_like 'a draw amount validator' do
      subject { premium_schedule }
    end

    context 'when rescheduling' do
      let(:loan) { rescheduled_premium_schedule.loan }
      let(:rescheduled_premium_schedule) { FactoryGirl.build(:rescheduled_premium_schedule) }

      it_should_behave_like 'a draw amount validator' do
        subject { rescheduled_premium_schedule }
      end

      it "does not require initial draw year" do
        rescheduled_premium_schedule.initial_draw_year = nil
        expect(rescheduled_premium_schedule).to be_valid
      end

      %w(
        premium_cheque_month
        initial_draw_amount
        repayment_duration
      ).each do |attr|
        it "is invalid without #{attr}" do
          rescheduled_premium_schedule.send("#{attr}=", '')
          expect(rescheduled_premium_schedule).not_to be_valid
        end
      end

      it 'must have a correctly formatted premium_cheque_month' do
        rescheduled_premium_schedule.premium_cheque_month = 'blah'
        expect(rescheduled_premium_schedule).not_to be_valid
        rescheduled_premium_schedule.premium_cheque_month = '1/12'
        expect(rescheduled_premium_schedule).not_to be_valid
        rescheduled_premium_schedule.premium_cheque_month = '29/2015'
        expect(rescheduled_premium_schedule).not_to be_valid
        rescheduled_premium_schedule.premium_cheque_month = '09/2015'
        expect(rescheduled_premium_schedule).to be_valid
      end

      it "is not valid when premium cheque month is in the past" do
        rescheduled_premium_schedule.premium_cheque_month = "03/2012"
        expect(rescheduled_premium_schedule).not_to be_valid
      end

      it "is not valid when premium cheque month is current month" do
        rescheduled_premium_schedule.premium_cheque_month = Date.current.strftime('%m/%Y')
        expect(rescheduled_premium_schedule).not_to be_valid
      end

      it "is valid when premium cheque month is next month" do
        rescheduled_premium_schedule.premium_cheque_month = Date.current.next_month.strftime('%m/%Y')
        expect(rescheduled_premium_schedule).to be_valid
      end

      it "is valid when premium cheque month number is less than current month but in a future year" do
        Timecop.freeze(Date.new(2012, 8, 23)) do
          rescheduled_premium_schedule.premium_cheque_month = "07/2013"
          expect(rescheduled_premium_schedule).to be_valid
        end
      end

      it "is valid with differing values for loan amount and total draw amounth" do
        loan.amount = 10_000_00
        rescheduled_premium_schedule.initial_draw_amount = 10_00
        expect(rescheduled_premium_schedule).to be_valid
      end
    end
  end

  describe "sequence" do
    let(:premium_schedule) { FactoryGirl.build(:premium_schedule) }

    it "should be set before validation on create" do
      expect(premium_schedule.seq).to be_nil
      premium_schedule.valid?
      expect(premium_schedule.seq).to eq(0)
    end

    it "should increment by 1 when state aid calculation for the same loan exists" do
      premium_schedule.save!
      new_premium_schedule = FactoryGirl.build(:premium_schedule, loan: premium_schedule.loan)

      new_premium_schedule.valid?

      expect(new_premium_schedule.seq).to eq(1)
    end
  end

  describe "reschedule?" do
    let(:premium_schedule) { FactoryGirl.build(:premium_schedule) }

    it "should return true when reschedule calculation type" do
      premium_schedule.calc_type = PremiumSchedule::RESCHEDULE_TYPE
      expect(premium_schedule).to be_reschedule
    end

    it "should return false when schedule calculation type" do
      premium_schedule.calc_type = PremiumSchedule::SCHEDULE_TYPE
      expect(premium_schedule).not_to be_reschedule
    end
  end

  describe '#total_premiums' do
    context "legacy calculation" do
      let(:premium_schedule) {
        FactoryGirl.build(:premium_schedule,
          initial_draw_amount: Money.new(100_000_00),
          repayment_duration: 120)
      }

      it 'calculates total premiums for legacy premium schedules' do
        premium_schedule.loan.premium_rate = 2.0
        expect(premium_schedule.total_premiums).to eq(Money.new(10_250_00))
      end
    end

    context "non-legacy calculation" do
      let(:premium_schedule) {
        FactoryGirl.build(:premium_schedule,
          initial_draw_amount: Money.new(100_000_00),
          repayment_duration: 120,
          legacy_premium_calculation: false)
      }

      before do
        premium_schedule.loan.premium_rate = 2.0
      end

      it 'calculates total premiums for non-legacy premium schedules' do
        expect(premium_schedule.total_premiums).to eq(Money.new(10_250_00))
      end

      it 'returns a Money when repayment duration is 0' do
        premium_schedule.repayment_duration = 0
        expect(premium_schedule.total_premiums).to eq(Money.new(0))
      end
    end
  end

  describe '#subsequent_premiums' do
    context 'when not a reschedule' do
      let(:premium_schedule) { FactoryGirl.build(:premium_schedule, repayment_duration: 120) }

      it 'should not include first quarter when standard state aid calculation' do
        expect(premium_schedule.subsequent_premiums.size).to eq(39)
      end
    end

    context 'when a reschedule' do
      let(:premium_schedule) { FactoryGirl.build(:rescheduled_premium_schedule, repayment_duration: 120) }

      it 'should include first quarter when rescheduled state aid calculation' do
        expect(premium_schedule.subsequent_premiums.size).to eq(40)
      end
    end
  end

  describe '#total_subsequent_premiums' do
    before do
      premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Quarterly.id
      premium_schedule.loan.premium_rate = 2.00
    end

    context 'when not a reschedule' do
      context 'and there are subsequent premiums' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 12,
            initial_draw_amount: Money.new(10_000_00),
          )
        }

        it 'returns the correct total' do
          expect(premium_schedule.total_subsequent_premiums).to eq(Money.new(75_00))
        end
      end

      context 'and there are no subsequent premiums' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 3,
            initial_draw_amount: Money.new(10_000_00),
          )
        }

        it 'returns the correct total' do
          # Use eql since we explicitly want a Money object
          expect(premium_schedule.total_subsequent_premiums).to eql(Money.new(0))
        end
      end
    end
  end

  describe '#second_premium_collection_month' do
    let(:premium_schedule) { FactoryGirl.build(:premium_schedule, loan: loan) }
    let!(:loan) { FactoryGirl.create(:loan, :guaranteed) }

    it 'returns a formatted date string 3 months from the initial draw date ' do
      loan.initial_draw_change.update_attribute :date_of_change, Date.new(2012, 2, 24)

      expect(premium_schedule.second_premium_collection_month).to eq('05/2012')
    end

    it 'deals with end of month dates' do
      loan.initial_draw_change.update_attribute :date_of_change, Date.new(2011, 11, 30)

      expect(premium_schedule.second_premium_collection_month).to eq('02/2012')
    end

    it 'returns nil if there is no initial draw date' do
      LoanModification.delete_all

      expect(premium_schedule.second_premium_collection_month).to be_nil
    end
  end

  describe '#initial_premium_cheque' do
    context 'when not reschedule' do
      let(:premium_schedule) {
        FactoryGirl.build(:premium_schedule,
          initial_draw_amount: Money.new(100_000_00),
          repayment_duration: 120)
      }

      it 'returns the first premium amount' do
        expect(premium_schedule.initial_premium_cheque).to eq(premium_schedule.premiums.first)
      end
    end

    context 'when a reschedule' do
      let(:premium_schedule) {
        FactoryGirl.build(:rescheduled_premium_schedule,
          initial_draw_amount: Money.new(100_000_00),
          repayment_duration: 120)
      }

      it 'returns 0 money' do
        expect(premium_schedule.initial_premium_cheque).to eq(Money.new(0))
      end
    end
  end

  describe '#drawdowns' do
    let(:drawdowns) { premium_schedule.drawdowns }

    context 'when there is a single drawdown' do
      let(:premium_schedule) {
        FactoryGirl.build(:rescheduled_premium_schedule,
          initial_draw_amount: Money.new(100_000_00))
      }

      it 'returns an array containing one drawdown' do
        expect(drawdowns.size).to eq(1)

        expect(drawdowns[0].amount).to eq(Money.new(100_000_00))
        expect(drawdowns[0].month).to eq(0)
      end
    end

    context 'when there are multiple drawdowns' do
      let(:premium_schedule) {
        FactoryGirl.build(:rescheduled_premium_schedule,
          initial_draw_amount: Money.new(100_000_00),
          second_draw_amount: Money.new(75_000_00),
          second_draw_months: 2,
          third_draw_amount: Money.new(50_000_00),
          third_draw_months: 4,
          fourth_draw_amount: Money.new(25_000_00),
          fourth_draw_months: 6)
      }

      it 'returns an array containing all drawdowns' do
        expect(drawdowns.size).to eq(4)

        expect(drawdowns[0].amount).to eq(Money.new(100_000_00))
        expect(drawdowns[0].month).to eq(0)

        expect(drawdowns[1].amount).to eq(Money.new(75_000_00))
        expect(drawdowns[1].month).to eq(2)

        expect(drawdowns[2].amount).to eq(Money.new(50_000_00))
        expect(drawdowns[2].month).to eq(4)

        expect(drawdowns[3].amount).to eq(Money.new(25_000_00))
        expect(drawdowns[3].month).to eq(6)
      end
    end
  end

  describe '#premiums' do
    before do
      premium_schedule.loan.premium_rate = 2.00
    end

    context 'when using legacy premium calculation logic' do
      it_should_behave_like 'premium payments for a loan repaid on a monthly or quarterly basis' do
        let(:legacy_premium_calculation) { true }
        let(:repayment_frequency) { RepaymentFrequency::Monthly }
      end

      context 'and there are drawdowns on non-quarter months' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 48,
            initial_draw_amount: Money.new(95_000_00),
            second_draw_amount: Money.new(45_000_00),
            second_draw_months: 2,
            legacy_premium_calculation: true
          )
        }

        it 'returns the correct premium payments' do
          expect(premium_schedule.premiums).to eq([
            Money.new(47500),
            Money.new(66542),
            Money.new(62106),
            Money.new(57670),
            Money.new(53234),
            Money.new(48798),
            Money.new(44361),
            Money.new(39925),
            Money.new(35489),
            Money.new(31053),
            Money.new(26617),
            Money.new(22181),
            Money.new(17745),
            Money.new(13308),
            Money.new(8872),
            Money.new(4436),
          ])
        end
      end

      context 'and the loan term does not contain an exact number of quarters' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 14, # <-- not evenly divisible by 3
            initial_draw_amount: Money.new(36_000_00),
            legacy_premium_calculation: true
          )
        }

        it 'returns the correct premium payments, missing off the final one' do
          expect(premium_schedule.premiums).to eq([
            Money.new(18000),
            Money.new(14143),
            Money.new(10286),
            Money.new(6429),
          ])
        end
      end
    end

    context 'when not using legacy premium calculation logic' do
      context 'and the repayment frequency is quarterly' do
        it_should_behave_like 'premium payments for a loan repaid on a monthly or quarterly basis' do
          let(:legacy_premium_calculation) { false }
          let(:repayment_frequency) { RepaymentFrequency::Quarterly }
        end

        context 'and there are drawdowns on non-quarter months' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 48,
              initial_draw_amount: Money.new(95_000_00),
              second_draw_amount: Money.new(45_000_00),
              second_draw_months: 2,
              legacy_premium_calculation: false
            )
          }

          it 'returns the correct premium payments' do
            premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Quarterly.id

            expect(premium_schedule.premiums).to eq([
              Money.new(47500),
              Money.new(65625),
              Money.new(61250),
              Money.new(56875),
              Money.new(52500),
              Money.new(48125),
              Money.new(43750),
              Money.new(39375),
              Money.new(35000),
              Money.new(30625),
              Money.new(26250),
              Money.new(21875),
              Money.new(17500),
              Money.new(13125),
              Money.new(8750),
              Money.new(4375),
            ])
          end
        end

        context 'and the loan term does not contain an exact number of quarters' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 14, # <-- not evenly divisible by 3
              initial_draw_amount: Money.new(36_000_00),
              legacy_premium_calculation: false
            )
          }

          it 'returns the correct premium payments (one more than the legacy calculation)' do
            premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Quarterly.id

            expect(premium_schedule.premiums).to eq([
              Money.new(18000),
              Money.new(14143),
              Money.new(10286),
              Money.new(6429),
              Money.new(2571),
            ])
          end
        end
      end

      context 'and the repayment frequency is monthly' do
        it_should_behave_like 'premium payments for a loan repaid on a monthly or quarterly basis' do
          let(:legacy_premium_calculation) { false }
          let(:repayment_frequency) { RepaymentFrequency::Monthly }
        end

        context 'and there are drawdowns on non-quarter months' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 48,
              initial_draw_amount: Money.new(95_000_00),
              second_draw_amount: Money.new(45_000_00),
              second_draw_months: 2,
              legacy_premium_calculation: false
            )
          }

          it 'returns the correct premium payments' do
            premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Monthly.id

            expect(premium_schedule.premiums).to eq([
              Money.new(47500),
              Money.new(66542),
              Money.new(62106),
              Money.new(57670),
              Money.new(53234),
              Money.new(48798),
              Money.new(44361),
              Money.new(39925),
              Money.new(35489),
              Money.new(31053),
              Money.new(26617),
              Money.new(22181),
              Money.new(17745),
              Money.new(13308),
              Money.new(8872),
              Money.new(4436),
            ])
          end
        end

        context 'and the loan term does not contain an exact number of quarters' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 14, # <-- not evenly divisible by 3
              initial_draw_amount: Money.new(36_000_00),
              legacy_premium_calculation: false
            )
          }

          it 'returns the correct premium payments (one more than the legacy calculation)' do
            premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Monthly.id

            expect(premium_schedule.premiums).to eq([
              Money.new(18000),
              Money.new(14143),
              Money.new(10286),
              Money.new(6429),
              Money.new(2571),
            ])
          end
        end
      end

      context 'and the repayment frequency is six-monthly' do
        before do
          premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::SixMonthly.id
        end

        context 'when there is a single drawdown' do
          context 'and no repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 36,
                initial_draw_amount: Money.new(75_000_00),
                legacy_premium_calculation: false,
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(37500),
                Money.new(37500),
                Money.new(31250),
                Money.new(31250),
                Money.new(25000),
                Money.new(25000),
                Money.new(18750),
                Money.new(18750),
                Money.new(12500),
                Money.new(12500),
                Money.new(6250),
                Money.new(6250),
              ])
            end
          end

          context 'and a repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 36,
                initial_draw_amount: Money.new(50_000_00),
                legacy_premium_calculation: false,
                initial_capital_repayment_holiday: 12
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(18750),
                Money.new(18750),
                Money.new(12500),
                Money.new(12500),
                Money.new(6250),
                Money.new(6250)
              ])
            end
          end
        end

        context 'when there are four drawdowns' do
          context 'and no repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 24,
                initial_draw_amount: Money.new(250_000_00),
                second_draw_amount: Money.new(250_000_00),
                second_draw_months: 1,
                third_draw_amount: Money.new(250_000_00),
                third_draw_months: 2,
                fourth_draw_amount: Money.new(250_000_00),
                fourth_draw_months: 3,
                legacy_premium_calculation: false,
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(125000),
                Money.new(500000),
                Money.new(375000),
                Money.new(375000),
                Money.new(250000),
                Money.new(250000),
                Money.new(125000),
                Money.new(125000),
              ])
            end
          end
        end
      end

      context 'and the repayment frequency is annually' do
        before do
          premium_schedule.loan.repayment_frequency_id = RepaymentFrequency::Annually.id
        end

        context 'when there is a single drawdown' do
          context 'and no repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 24,
                initial_draw_amount: Money.new(350_000_00),
                legacy_premium_calculation: false
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(175000),
                Money.new(175000),
                Money.new(175000),
                Money.new(175000),
                Money.new(87500),
                Money.new(87500),
                Money.new(87500),
                Money.new(87500),
              ])
            end
          end

          context 'and a repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 48,
                initial_draw_amount: Money.new(50_000_00),
                legacy_premium_calculation: false,
                initial_capital_repayment_holiday: 24
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(25000),
                Money.new(12500),
                Money.new(12500),
                Money.new(12500),
                Money.new(12500)
              ])
            end
          end
        end

        context 'when there are three drawdowns' do
          context 'and no repayment holiday' do
            let(:premium_schedule) {
              FactoryGirl.build_stubbed(:premium_schedule,
                repayment_duration: 24,
                initial_draw_amount: Money.new(700_000_00),
                second_draw_amount: Money.new(100_000_00),
                second_draw_months: 1,
                third_draw_amount: Money.new(200_000_00),
                third_draw_months: 5,
                legacy_premium_calculation: false
              )
            }

            it 'returns the correct premium payments' do
              expect(premium_schedule.premiums).to eq([
                Money.new(350000),
                Money.new(400000),
                Money.new(500000),
                Money.new(500000),
                Money.new(250000),
                Money.new(250000),
                Money.new(250000),
                Money.new(250000),
              ])
            end
          end
        end

        context 'when there are four drawdowns' do
          context 'and no repayment holiday' do
            context 'and a repayment duration which is a multiple of 12 (months)' do
              let(:premium_schedule) {
                FactoryGirl.build_stubbed(:premium_schedule,
                  repayment_duration: 24,
                  initial_draw_amount: Money.new(100_000_00),
                  second_draw_amount: Money.new(100_000_00),
                  second_draw_months: 1,
                  third_draw_amount: Money.new(100_000_00),
                  third_draw_months: 2,
                  fourth_draw_amount: Money.new(100_000_00),
                  fourth_draw_months: 6,
                  legacy_premium_calculation: false,
                )
              }

              it 'returns the correct premium payments' do
                expect(premium_schedule.premiums).to eq([
                  Money.new(50000),
                  Money.new(150000),
                  Money.new(200000),
                  Money.new(200000),
                  Money.new(100000),
                  Money.new(100000),
                  Money.new(100000),
                  Money.new(100000),
                ])
              end
            end

            context 'and a repayment duration which is not a multiple of 12 (months)' do
              let(:premium_schedule) {
                FactoryGirl.build_stubbed(:premium_schedule,
                  repayment_duration: 68, # <-- not evenly divisible by 12
                  initial_draw_amount: Money.new(171_275_00),
                  second_draw_amount: Money.new(171_275_00),
                  second_draw_months: 2,
                  legacy_premium_calculation: false,
                )
              }

              it 'returns the correct premium payments' do
                expect(premium_schedule.premiums).to eq([
                  Money.new(85638),
                  Money.new(171275),
                  Money.new(171275),
                  Money.new(171275),
                  Money.new(142729),
                  Money.new(142729),
                  Money.new(142729),
                  Money.new(142729),
                  Money.new(114183),
                  Money.new(114183),
                  Money.new(114183),
                  Money.new(114183),
                  Money.new(85638),
                  Money.new(85638),
                  Money.new(85638),
                  Money.new(85638),
                  Money.new(57092),
                  Money.new(57092),
                  Money.new(57092),
                  Money.new(57092),
                  Money.new(28546),
                  Money.new(28546),
                  Money.new(28546),
                ])
              end
            end
          end
        end
      end
    end

    context 'when the loan has a repayment frequency id of 0' do
      let(:premium_schedule) {
        FactoryGirl.build_stubbed(:premium_schedule,
          repayment_duration: 12,
          initial_draw_amount: Money.new(12_000_00),
          legacy_premium_calculation: false
        )
      }

      before do
        premium_schedule.loan.repayment_frequency_id = 0
      end

      it 'does not raise an exception' do
        expect {
          premium_schedule.premiums
        }.to_not raise_exception
      end
    end
  end
end
