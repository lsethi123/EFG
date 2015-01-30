require 'spec_helper'

describe PremiumScheduleReport do
  describe 'validations' do
    let(:premium_schedule_report) { PremiumScheduleReport.new }

    it 'is invalid with nothing set' do
      expect(premium_schedule_report).not_to be_valid
    end

    context '#loan_reference' do
      it 'makes everything good' do
        premium_schedule_report.loan_reference = 'ABC'
        expect(premium_schedule_report).to be_valid
      end
    end

    context '#collection_month' do
      it 'must be in the correct format' do
        premium_schedule_report.loan_reference = 'ABC'
        expect(premium_schedule_report).to be_valid
        premium_schedule_report.collection_month = 'zzz'
        expect(premium_schedule_report).not_to be_valid
      end
    end

    context 'schedule_type "All"' do
      before do
        premium_schedule_report.schedule_type = 'All'
      end

      context 'with a collection_month' do
        before do
          premium_schedule_report.collection_month = '1/2012'
        end

        it 'is not valid without a start_on or finish_on' do
          expect(premium_schedule_report).not_to be_valid
        end

        it 'is valid with a start_on (or finish_on)' do
          premium_schedule_report.start_on = '1/1/11'
          expect(premium_schedule_report).to be_valid
        end

        it 'is valid with a finish_on (or start_on)' do
          premium_schedule_report.finish_on = '1/1/11'
          expect(premium_schedule_report).to be_valid
        end
      end

      context 'with a start_on' do
        before do
          premium_schedule_report.start_on = '1/1/11'
        end

        it 'is not valid without a collection_month' do
          expect(premium_schedule_report).not_to be_valid
        end

        it 'is valid with a collection_month' do
          premium_schedule_report.collection_month = '1/2012'
          expect(premium_schedule_report).to be_valid
        end
      end

      context 'with a finish_on' do
        before do
          premium_schedule_report.finish_on = '1/1/11'
        end

        it 'is not valid without a collection_month' do
          expect(premium_schedule_report).not_to be_valid
        end

        it 'is valid with a collection_month' do
          premium_schedule_report.collection_month = '1/2012'
          expect(premium_schedule_report).to be_valid
        end
      end
    end

    context 'schedule_type "Changed"' do
      before do
        premium_schedule_report.schedule_type = 'Changed'
      end

      it 'is invalid without a collection_month' do
        expect(premium_schedule_report).not_to be_valid
      end

      it 'is valid with a collection_month' do
        premium_schedule_report.collection_month = '1/2012'
        expect(premium_schedule_report).to be_valid
      end

      it 'cannot have start_on' do
        premium_schedule_report.collection_month = '1/2012'
        premium_schedule_report.start_on = '1/1/11'
        expect(premium_schedule_report).not_to be_valid
      end

      it 'cannot have finish_on' do
        premium_schedule_report.collection_month = '1/2012'
        premium_schedule_report.finish_on = '1/1/11'
        expect(premium_schedule_report).not_to be_valid
      end
    end

    context 'schedule_type "New"' do
      before do
        premium_schedule_report.schedule_type = 'New'
      end

      it 'is invalid without a start_on or finish_on' do
        expect(premium_schedule_report).not_to be_valid
      end

      it 'requires start_on (or finish_on)' do
        premium_schedule_report.start_on = '1/1/11'
        expect(premium_schedule_report).to be_valid
      end

      it 'requires finish_on (or start_on)' do
        premium_schedule_report.finish_on = '1/1/11'
        expect(premium_schedule_report).to be_valid
      end

      it 'cannot have collection_month' do
        premium_schedule_report.start_on = '1/1/11'
        premium_schedule_report.collection_month = '01/2011'
        expect(premium_schedule_report).not_to be_valid
      end
    end
  end

  describe '#loans' do
    let(:premium_schedule_report) { PremiumScheduleReport.new }
    let(:loan1) { FactoryGirl.create(:loan, :guaranteed, loan_scheme: 'E', loan_source: 'L') }
    let(:loan2) { FactoryGirl.create(:loan, :guaranteed, loan_scheme: 'E', loan_source: 'S', reference: 'ABC') }
    let(:loan3) { FactoryGirl.create(:loan, :guaranteed, loan_scheme: 'S', loan_source: 'S') }
    let!(:premium_schedule1) { FactoryGirl.create(:premium_schedule, loan: loan1, calc_type: 'S', premium_cheque_month: '01/2011') }
    let!(:premium_schedule2) { FactoryGirl.create(:premium_schedule, loan: loan2, calc_type: 'R', premium_cheque_month: "01/#{Date.current.year + 1}") }
    let!(:premium_schedule3) { FactoryGirl.create(:premium_schedule, loan: loan3, calc_type: 'N', premium_cheque_month: '02/2011') }

    before do
      loan1.initial_draw_change.update_attribute :date_of_change, '1/1/11'
      loan2.initial_draw_change.update_attribute :date_of_change, '2/1/11'
      loan3.initial_draw_change.update_attribute :date_of_change, '3/1/11'

      loan1.initial_draw_change.update_attribute :modified_date, '1/1/11'
      loan2.initial_draw_change.update_attribute :modified_date, '2/1/11'
      loan3.initial_draw_change.update_attribute :modified_date, '3/1/11'
    end

    let(:loan_ids) { premium_schedule_report.loans.map(&:id) }

    it 'returns the loans' do
      expect(loan_ids).to include(loan1.id)
      expect(loan_ids).to include(loan2.id)
      expect(loan_ids).to include(loan3.id)
    end

    context 'with combination of conditions' do
      it do
        premium_schedule_report.loan_type = 'Legacy'
        premium_schedule_report.loan_scheme = 'EFG only'
        premium_schedule_report.schedule_type = 'All'
        premium_schedule_report.collection_month = '01/2011'
        premium_schedule_report.start_on = '01/01/2011'

        expect(premium_schedule_report).to be_valid
        expect(loan_ids).to eq([ loan1.id ])
      end
    end

    context 'with schedule_type' do
      it do
        premium_schedule_report.schedule_type = 'All'
        expect(loan_ids.length).to eq(3)
      end

      context '"New"' do
        before do
          premium_schedule_report.schedule_type = 'New'
        end

        context 'draw_down_date' do
          before do
            FactoryGirl.create(:loan_change, loan: loan1, date_of_change: '11/2/2011')
            FactoryGirl.create(:loan_change, loan: loan3, date_of_change: '12/2/2011')
          end

          it do
            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).to include(loan3.id)
          end

          it 'pulls the draw_down_date from the first loan_change' do
            expect(premium_schedule_report.loans.first.draw_down_date).to eq(Date.new(2011, 1, 1))
            expect(premium_schedule_report.loans.last.draw_down_date).to eq(Date.new(2011, 1, 3))
          end
        end

        context 'with start_on / finish_on' do
          it do
            premium_schedule_report.start_on = '1/1/2011'

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).to include(loan3.id)
          end

          it do
            premium_schedule_report.start_on = '1/1/2011'
            premium_schedule_report.finish_on = '1/1/2011'

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).not_to include(loan3.id)
          end

          it do
            premium_schedule_report.start_on = '1/1/2011'
            premium_schedule_report.finish_on = '2/1/2011'

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).not_to include(loan3.id)
          end

          it do
            premium_schedule_report.start_on = '2/1/2011'

            expect(loan_ids).not_to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).to include(loan3.id)
          end

          it do
            premium_schedule_report.finish_on = '3/1/2011'

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).to include(loan3.id)
          end

          it do
            premium_schedule_report.finish_on = '1/1/2011'

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).not_to include(loan3.id)
          end
        end
      end

      context '"Changed"' do
        before do
          premium_schedule_report.schedule_type = 'Changed'
        end

        it do
          expect(loan_ids).not_to include(loan1.id)
          expect(loan_ids).to include(loan2.id)
          expect(loan_ids).not_to include(loan3.id)
        end

        it 'includes all rescheduled loans' do
          FactoryGirl.create(:premium_schedule, loan: loan1, calc_type: 'R', premium_cheque_month: "03/#{Date.current.year + 1}")
          FactoryGirl.create(:premium_schedule, loan: loan3, calc_type: 'R', premium_cheque_month: "03/#{Date.current.year + 1}")

          expect(loan_ids).to include(loan1.id)
          expect(loan_ids).to include(loan2.id)
          expect(loan_ids).to include(loan3.id)
        end

        context 'draw_down_date' do
          before do
            FactoryGirl.create(:loan_change, loan: loan2, date_of_change: '2/3/2012')
            FactoryGirl.create(:loan_change, loan: loan2, date_of_change: '3/3/2012')
          end

          it 'pulls the draw_down_date from the first loan_change' do
            expect(premium_schedule_report.loans.first.draw_down_date).to eq(Date.new(2011, 1, 2))
          end
        end

        context 'with collection_month' do
          before do
            FactoryGirl.create(:premium_schedule, loan: loan1, calc_type: 'R', premium_cheque_month: "04/#{Date.current.year + 1}")
            FactoryGirl.create(:premium_schedule, loan: loan2, calc_type: 'R', premium_cheque_month: "04/#{Date.current.year + 1}")
            FactoryGirl.create(:premium_schedule, loan: loan3, calc_type: 'R', premium_cheque_month: "05/#{Date.current.year + 1}")
          end

          it do
            premium_schedule_report.collection_month = "04/#{Date.current.year + 1}"

            expect(loan_ids).to include(loan1.id)
            expect(loan_ids).to include(loan2.id)
            expect(loan_ids).not_to include(loan3.id)
          end

          it do
            premium_schedule_report.collection_month = "04/#{Date.current.year + 2}"

            expect(loan_ids).not_to include(loan1.id)
            expect(loan_ids).not_to include(loan2.id)
            expect(loan_ids).not_to include(loan3.id)
          end
        end
      end
    end

    context 'with a lender_id' do
      it 'includes only loans from that lender' do
        premium_schedule_report.lender_id = loan1.lender_id
        expect(premium_schedule_report.loans).to include(loan1)
        expect(premium_schedule_report.loans).not_to include(loan2)
        expect(premium_schedule_report.loans).not_to include(loan3)
      end
    end

    context 'with a loan_reference' do
      it do
        premium_schedule_report.loan_reference = 'ABC'
        expect(premium_schedule_report.loans).not_to include(loan1)
        expect(premium_schedule_report.loans).to include(loan2)
        expect(premium_schedule_report.loans).not_to include(loan3)
      end
    end

    context 'with a loan_scheme' do
      it do
        premium_schedule_report.loan_scheme = 'All'
        expect(premium_schedule_report.loans.length).to eq(3)
      end

      it do
        premium_schedule_report.loan_scheme = 'SFLG Only'
        expect(premium_schedule_report.loans).not_to include(loan1)
        expect(premium_schedule_report.loans).not_to include(loan2)
        expect(premium_schedule_report.loans).to include(loan3)
      end

      it do
        premium_schedule_report.loan_scheme = 'EFG Only'
        expect(premium_schedule_report.loans).to include(loan1)
        expect(premium_schedule_report.loans).to include(loan2)
        expect(premium_schedule_report.loans).not_to include(loan3)
      end
    end

    context 'with a loan_type' do
      it do
        premium_schedule_report.loan_type = 'All'
        expect(premium_schedule_report.loans.length).to eq(3)
      end

      it do
        premium_schedule_report.loan_type = 'New'
        expect(premium_schedule_report.loans).not_to include(loan1)
        expect(premium_schedule_report.loans).to include(loan2)
        expect(premium_schedule_report.loans).to include(loan3)
      end

      it do
        premium_schedule_report.loan_type = 'Legacy'
        expect(premium_schedule_report.loans).to include(loan1)
        expect(premium_schedule_report.loans).not_to include(loan2)
        expect(premium_schedule_report.loans).not_to include(loan3)
      end
    end
  end

  describe '#to_csv' do
    let!(:lender) { FactoryGirl.create(:lender, organisation_reference_code: 'Z') }

    let!(:loan) { FactoryGirl.create(:loan, lender: lender, reference: 'ABC') }

    let(:premium_schedule_report) { PremiumScheduleReport.new }

    let(:csv) { CSV.parse(premium_schedule_report.to_csv) }

    let(:row) { csv[1] }

    before do
      FactoryGirl.create(:loan_change, loan: loan, date_of_change: '3/11/2011')
    end

    context 'with standard state aid calculation' do

      before do
        FactoryGirl.create(:premium_schedule, loan: loan, calc_type: 'S', premium_cheque_month: '2/2011')
      end

      it 'should return 2 rows of data' do
        expect(csv.length).to eq(2)
      end

      it 'should return loan premium schedule details' do
        expect(row[0]).to eq('03-11-2011')
        expect(row[1]).to eq('Z')
        expect(row[2]).to eq('ABC')
        expect(row[3]).to eq('S')
        expect(row[4]).to eq('61.72')
        expect(row[5]).to eq('2/2011')
        expect(row[6]).to eq('3')
        expect(row[7]).to eq('0.0')
        expect(row[8]).to eq('46.29')
        expect(row[9]).to eq('30.86')
        expect(row[10]).to eq('15.43')
        expect(row[11]).to eq('0.0')
        expect(row[12]).to eq('0.0')
        expect(row[13]).to eq('0.0')
        expect(row[14]).to eq('0.0')
        expect(row[15]).to eq('0.0')
        expect(row[16]).to eq('0.0')
        expect(row[17]).to eq('0.0')
        expect(row[18]).to eq('0.0')
        expect(row[19]).to eq('0.0')
        expect(row[20]).to eq('0.0')
        expect(row[21]).to eq('0.0')
        expect(row[22]).to eq('0.0')
        expect(row[23]).to eq('0.0')
        expect(row[24]).to eq('0.0')
        expect(row[25]).to eq('0.0')
        expect(row[26]).to eq('0.0')
        expect(row[27]).to eq('0.0')
        expect(row[28]).to eq('0.0')
        expect(row[29]).to eq('0.0')
        expect(row[30]).to eq('0.0')
        expect(row[31]).to eq('0.0')
        expect(row[32]).to eq('0.0')
        expect(row[33]).to eq('0.0')
        expect(row[34]).to eq('0.0')
        expect(row[35]).to eq('0.0')
        expect(row[36]).to eq('0.0')
        expect(row[37]).to eq('0.0')
        expect(row[38]).to eq('0.0')
        expect(row[39]).to eq('0.0')
        expect(row[40]).to eq('0.0')
        expect(row[41]).to eq('0.0')
        expect(row[42]).to eq('0.0')
        expect(row[43]).to eq('0.0')
        expect(row[44]).to eq('0.0')
        expect(row[45]).to eq('0.0')
        expect(row[46]).to eq('0.0')
      end
    end

    context 'with rescheduled state aid calculation' do
      before do
        FactoryGirl.create(:rescheduled_premium_schedule, loan: loan)
      end

      it 'sets schedule type correctly' do
        expect(row[3]).to eq('R')
      end

      it 'includes first premium amount' do
        expect(row[7]).to eq('61.72')
      end
    end

    context "with state aid calculation without premium cheque month" do
      before do
        premium_schedule = FactoryGirl.create(:premium_schedule, loan: loan)
        premium_schedule.update_attribute(:premium_cheque_month, "")
      end

      it 'sets first collection date to 3 months after guarantee date' do
        expect(row[5]).to eq("02/2012")
      end
    end

    context "where loan has scheduled and re-scheduled state aid calculations" do
      let!(:scheduled_premium_schedule) { FactoryGirl.create(:premium_schedule, loan: loan) }
      let!(:rescheduled_premium_schedule) { FactoryGirl.create(:rescheduled_premium_schedule, loan: loan) }

      let(:row1) { csv[1] }
      let(:row2) { csv[2] }

      it "should include a row for both state aid calculations" do
        expect(csv.length).to eq(3)
      end

      it "should set the correct calc type for scheduled state aid calculation" do
        expect(row1[3]).to eq('S')
      end

      it "should set the correct premiums for scheduled state aid calculation" do
        # the first premium is set to 0.0 for premium schedules with calc type 'S'
        expected_premiums = scheduled_premium_schedule.premiums.collect { |p| p.to_f.to_s }
        expected_premiums[0] = "0.0"

        expect(row1[7, expected_premiums.size]).to eq(expected_premiums)
      end

      it "should set the correct calc type for re-scheduled state aid calculation" do
        expect(row2[3]).to eq('R')
      end

      it "should set the correct premiums for re-scheduled state aid calculation" do
        expected_premiums = rescheduled_premium_schedule.premiums.collect { |p| p.to_f.to_s }

        expect(row2[7, expected_premiums.size]).to eq(expected_premiums)
      end
    end

    context "with Notified Aid calc type" do
      before do
        FactoryGirl.create(:premium_schedule, loan: loan, calc_type: PremiumSchedule::NOTIFIED_AID_TYPE)
      end

      it "sets Schedule Type value to 'S' instead of 'N'" do
        expect(row[3]).to eq('S')
      end
    end

    context "with ZeroDivisionError raised in " do
      it "should log the output and the exception and the loan" do
        loan = double(inspect: '#<Loan id:1>')
        row = double(loan: loan)
        row.stub(:to_csv).and_raise(ZeroDivisionError)
        PremiumScheduleReportRow.stub(:from_loans).and_return([row])

        logger = double
        expect(logger).to receive(:error).with("PremiumScheduleReport Error: ZeroDivisionError reporting on #<Loan id:1>")
        Rails.stub(:logger).and_return(logger)

        premium_schedule_report.to_csv
      end
    end

  end
end
