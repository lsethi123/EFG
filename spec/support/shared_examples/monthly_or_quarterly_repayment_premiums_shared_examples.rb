shared_examples_for 'premium payments for a loan repaid on a monthly or quarterly basis' do
  before do
    premium_schedule.loan.premium_rate = 2.00
    premium_schedule.loan.repayment_frequency_id = repayment_frequency.id
  end

  context 'when the loan term contains an exact number of quarters' do
    context 'and all drawdowns are on quarter months' do
      context 'when there is a single drawdown' do
        context 'and no repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 63,
              initial_draw_amount: Money.new(7_137_65),
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(3569),
              Money.new(3399),
              Money.new(3229),
              Money.new(3059),
              Money.new(2889),
              Money.new(2719),
              Money.new(2549),
              Money.new(2379),
              Money.new(2209),
              Money.new(2039),
              Money.new(1869),
              Money.new(1699),
              Money.new(1530),
              Money.new(1360),
              Money.new(1190),
              Money.new(1020),
              Money.new(850),
              Money.new(680),
              Money.new(510),
              Money.new(340),
              Money.new(170),
            ])
          end
        end

        context 'and a repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 24,
              initial_capital_repayment_holiday: 12,
              initial_draw_amount: Money.new(160_000_00),
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(80000),
              Money.new(80000),
              Money.new(80000),
              Money.new(80000),
              Money.new(80000),
              Money.new(60000),
              Money.new(40000),
              Money.new(20000),
            ])
          end
        end
      end

      context 'when there are two drawdowns taken on quarter months' do
        context 'and no repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 60,
              initial_draw_amount: Money.new(300_000_00),
              second_draw_amount: Money.new(100_000_00),
              second_draw_months: 3,
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(150000),
              Money.new(192500),
              Money.new(182368),
              Money.new(172237),
              Money.new(162105),
              Money.new(151974),
              Money.new(141842),
              Money.new(131711),
              Money.new(121579),
              Money.new(111447),
              Money.new(101316),
              Money.new(91184),
              Money.new(81053),
              Money.new(70921),
              Money.new(60789),
              Money.new(50658),
              Money.new(40526),
              Money.new(30395),
              Money.new(20263),
              Money.new(10132)
            ])
          end
        end
      end

      context 'when there are three drawdowns taken on quarter months' do
        context 'and no repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 12,
              initial_draw_amount: Money.new(12_000_00),
              second_draw_amount: Money.new(12_000_00),
              second_draw_months: 3,
              third_draw_amount: Money.new(12_000_00),
              third_draw_months: 6,
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(6000),
              Money.new(10500),
              Money.new(13000),
              Money.new(6500)
            ])
          end
        end
      end

      context 'when there are four drawdowns taken on quarter months' do
        context 'and no repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build(:premium_schedule,
              initial_draw_amount: Money.new(100_000_00),
              repayment_duration: 12,
              second_draw_amount: Money.new(50_000_00),
              second_draw_months: 3,
              third_draw_amount: Money.new(50_000_00),
              third_draw_months: 6,
              fourth_draw_amount: Money.new(800_000_00),
              fourth_draw_months: 9,
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(50000),
              Money.new(62500),
              Money.new(66667),
              Money.new(433333)
            ])
          end
        end

        context 'and a repayment holiday' do
          let(:premium_schedule) {
            FactoryGirl.build_stubbed(:premium_schedule,
              repayment_duration: 60,
              initial_capital_repayment_holiday: 6,
              initial_draw_amount: Money.new(100_000_00),
              second_draw_amount: Money.new(100_000_00),
              second_draw_months: 1,
              third_draw_amount: Money.new(100_000_00),
              third_draw_months: 2,
              fourth_draw_amount: Money.new(200_000_00),
              fourth_draw_months: 3,
              legacy_premium_calculation: legacy_premium_calculation,
            )
          }

          it 'returns the correct premium payments' do
            expect(premium_schedule.premiums).to eq([
              Money.new(50000),
              Money.new(250000),
              Money.new(250000),
              Money.new(236111),
              Money.new(222222),
              Money.new(208333),
              Money.new(194444),
              Money.new(180556),
              Money.new(166667),
              Money.new(152778),
              Money.new(138889),
              Money.new(125000),
              Money.new(111111),
              Money.new(97222),
              Money.new(83333),
              Money.new(69444),
              Money.new(55556),
              Money.new(41667),
              Money.new(27778),
              Money.new(13889)
            ])
          end
        end
      end

      context 'when there is a second drawdown in month 0' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 30,
            initial_draw_amount: Money.new(10_000_00),
            second_draw_amount: Money.new(10_000_00),
            second_draw_months: 0,
            legacy_premium_calculation: legacy_premium_calculation,
          )
        }

        it 'does not ignore the second drawdown and returns the correct premium payments' do
          expect(premium_schedule.premiums).to eq([
            Money.new(10000),
            Money.new(9000),
            Money.new(8000),
            Money.new(7000),
            Money.new(6000),
            Money.new(5000),
            Money.new(4000),
            Money.new(3000),
            Money.new(2000),
            Money.new(1000),
          ])
        end
      end

      context 'when the repayment duration is less than one quarter' do
        let(:premium_schedule) {
          FactoryGirl.build_stubbed(:premium_schedule,
            repayment_duration: 2,
            initial_draw_amount: Money.new(100_000_00),
            legacy_premium_calculation: legacy_premium_calculation,
          )
        }

        it 'returns the correct single premium payment' do
          expect(premium_schedule.premiums).to eq([
            Money.new(50000)
          ])
        end
      end
    end
  end
end
