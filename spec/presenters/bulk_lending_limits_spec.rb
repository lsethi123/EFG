require 'spec_helper'

describe BulkLendingLimits do
  describe "validations" do
    let!(:lender) { FactoryGirl.create(:lender) }
    let(:bulk_lending_limits) { FactoryGirl.build(:bulk_lending_limits) }

    it "should have a valid factory" do
      expect(bulk_lending_limits).to be_valid
    end

    it "should be invalid without a phase" do
      bulk_lending_limits.scheme_or_phase_id = nil
      expect(bulk_lending_limits).not_to be_valid
    end

    it 'requires a starts_on date' do
      bulk_lending_limits.starts_on = nil
      expect(bulk_lending_limits).not_to be_valid
    end

    it 'requires a ends_on date' do
      bulk_lending_limits.ends_on = nil
      expect(bulk_lending_limits).not_to be_valid
    end

    it 'requires a valid allocation_type_id' do
      bulk_lending_limits.allocation_type_id = ''
      expect(bulk_lending_limits).not_to be_valid
      bulk_lending_limits.allocation_type_id = '99'
      expect(bulk_lending_limits).not_to be_valid
      bulk_lending_limits.allocation_type_id = '1'
      expect(bulk_lending_limits).to be_valid
    end

    it 'requires a lending_limit_name' do
      bulk_lending_limits.lending_limit_name = ''
      expect(bulk_lending_limits).not_to be_valid
    end

    it 'requires ends_on to be after starts_on' do
      bulk_lending_limits.starts_on = Date.new(2012, 1, 2)
      bulk_lending_limits.ends_on = Date.new(2012, 1, 1)
      expect(bulk_lending_limits).not_to be_valid
    end

    it 'requires valid lender lending limits' do
      lender = bulk_lending_limits.lenders.first
      lender.allocation = nil
      lender.selected = true
      expect(bulk_lending_limits).not_to be_valid
    end
  end

  describe "#initialize" do
    let(:lender_attributes) { {
      id: '1',
      selected: '1',
      allocation: '123'
    } }

    let(:attributes) { {
      scheme_or_phase_id: 47,
      allocation_type_id: '1',
      lending_limit_name: 'lending limit name',
      starts_on: '1/1/12',
      ends_on: '31/12/12',
      lenders_attributes: { '0' => lender_attributes }
    } }

    let(:lender) { double(Lender, id: 1) }

    before do
      allow(Lender).to receive_message_chain(:active, :order_by_name).and_return([lender])
    end

    let(:bulk_lending_limits) { BulkLendingLimits.new(attributes) }

    subject { bulk_lending_limits }

    its(:scheme_or_phase_id) { should == 47 }
    its(:allocation_type_id) { should == 1 }
    its(:lending_limit_name) { should == 'lending limit name' }
    its(:starts_on) { should == Date.new(2012, 1, 1) }
    its(:ends_on) { should == Date.new(2012, 12, 31) }

    context "selected lenders" do
      subject { bulk_lending_limits.lenders.first }

      its(:allocation) { should == Money.new(12300) }
      it { should be_selected }
    end
  end

  describe "#lenders" do
    let(:bulk_lending_limits) { BulkLendingLimits.new }
    let(:lender) { double(Lender) }

    before { allow(Lender).to receive_message_chain(:active, :order_by_name).and_return([lender]) }

    subject { bulk_lending_limits.lenders }

    it "should use the order_by_name scope on Lenders" do
      scope = double('scope')
      expect(Lender).to receive(:active).and_return(scope)
      expect(scope).to receive(:order_by_name).and_return([lender])

      subject
    end

    its(:first) { should be_kind_of(LenderLendingLimit) }
  end

  describe "#save" do
    let(:lender_attributes) { {
      '0' => {
        id: lender1.id,
        selected: '0',
        allocation: '456'
      },
      '1' => {
        id: lender2.id,
        selected: '1',
        allocation: '123',
        active: '1'
      },
      '2' => {
        id: lender3.id,
        selected: '1',
        allocation: '123',
        active: '0'
      }
    } }

    let(:attributes) { {
      scheme_or_phase_id: phase.id,
      allocation_type_id: '1',
      lending_limit_name: 'lending limit name',
      starts_on: '1/1/12',
      ends_on: '31/12/12',
      lenders_attributes: lender_attributes
    } }

    let(:lender1) { FactoryGirl.create(:lender) }
    let(:lender2) { FactoryGirl.create(:lender) }
    let(:lender3) { FactoryGirl.create(:lender) }
    let(:phase) { Phase.find(5) }
    let(:user) { FactoryGirl.create(:cfe_admin) }

    before { allow(AdminAudit).to receive(:log) }

    let(:bulk_lending_limits) do
      bulk_lending_limits = BulkLendingLimits.new(attributes)
      bulk_lending_limits.created_by = user
      bulk_lending_limits
    end

    it "should create a lending limit" do
      expect {
        bulk_lending_limits.save
      }.to change(LendingLimit, :count).by(2)

      lending_limits = LendingLimit.all

      lending_limits.each do |lending_limit|
        expect(lending_limit.starts_on).to eq(Date.new(2012, 1, 1))
        expect(lending_limit.ends_on).to eq(Date.new(2012, 12, 31))
        expect(lending_limit.name).to eq('lending limit name')
        expect(lending_limit.allocation_type_id).to eq(1)
      end

      expect(lending_limits.map(&:lender)).to match_array([lender2, lender3])
      expect(lending_limits.to_a.count(&:active?)).to eq(1)
    end

    it "should create lending limits for selected lenders only" do
      expect {
        bulk_lending_limits.save
      }.to_not change(lender1.lending_limits, :count)
    end

    it "logs AdminAudit::LendingLimitCreated" do
      expect(AdminAudit).to receive(:log).with(AdminAudit::LendingLimitCreated, instance_of(LendingLimit), user)
      bulk_lending_limits.save
    end

    context "with SFLG scheme selected" do
      before { attributes[:scheme_or_phase_id] = Loan::SFLG_SCHEME }

      it "creates lending limits with a nil phase" do
        expect {
          bulk_lending_limits.save
        }.to change(LendingLimit, :count).by(2)

        lending_limits = LendingLimit.all

        lending_limits.each do |lending_limit|
          expect(lending_limit.phase).to be_nil
        end
      end
    end
  end
end
