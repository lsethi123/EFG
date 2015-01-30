require 'spec_helper'
require 'csv'

describe ClaimLimitsCsvExport do

  let(:lender) { FactoryGirl.build(:lender, name: 'Little Tinkers') }

  let(:claim_limit_calculator) { Phase1ClaimLimitCalculator.new(lender) }

  let(:claim_limits_csv_export) { ClaimLimitsCsvExport.new([ claim_limit_calculator ]) }

  before do
    allow(claim_limit_calculator).to receive_messages(
      amount_remaining: Money.new(50_000_00),
      cumulative_drawn_amount: Money.new(150_000_00),
      pre_claim_realisations_amount: Money.new(1_000_00),
      settled_amount: Money.new(49_000_00),
      total_amount: Money.new(100_000_00)
    )
  end

  describe ".header" do
    let(:header) { CSV.parse(claim_limits_csv_export.first).first }

    it "should return array of strings with correct text" do
      expect(header[0]).to eq(t(:lender_name))
      expect(header[1]).to eq(t(:phase))
      expect(header[2]).to eq(t(:claim_limit))
      expect(header[3]).to eq(t(:cumulative_drawn_amount))
      expect(header[4]).to eq(t(:settled))
      expect(header[5]).to eq(t(:pre_claim_limit_realisations))
      expect(header[6]).to eq(t(:claim_limit_remaining))
    end
  end

  describe "#generate" do
    let(:parsed_csv) { CSV.parse(claim_limits_csv_export.generate) }

    let(:row) { parsed_csv[1] }

    it "should return a row for the header and each claim limit" do
      expect(parsed_csv.size).to eq(2)
    end

    it "includes lender name" do
      expect(row[0]).to eq('Little Tinkers')
    end

    it "includes phase name" do
      expect(row[1]).to eq('Phase 1')
    end

    it "includes claim limit amount" do
      expect(row[2]).to eq(Money.new(100_000_00).to_s)
    end

    it "includes cumulative drawn amount" do
      expect(row[3]).to eq(Money.new(150_000_00).to_s)
    end

    it "includes settled amount" do
      expect(row[4]).to eq(Money.new(49_000_00).to_s)
    end

    it "includes pre-claim limit realisations amount" do
      expect(row[5]).to eq(Money.new(1_000_00).to_s)
    end

    it "includes claim limit remaining" do
      expect(row[6]).to eq(Money.new(50_000_00).to_s)
    end
  end

  private

  def t(key)
    I18n.t(key, scope: 'csv_headers.claim_limits_report')
  end

end
