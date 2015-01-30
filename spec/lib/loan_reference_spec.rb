require 'spec_helper'

describe LoanReference do

  describe "#initialize" do
    it "raises exception when invalid reference" do
      ['wrong', '1111111', 'A1B2C3D', 'ABC123-01', 'ABC123+01', 'ABC12345+04', 'ABC1234+100', '', nil].each do |string|
        expect {
          LoanReference.new(string)
        }.to raise_error(InvalidLoanReference), "#{string} should not be a valid legacy loan reference"
      end
    end

    it "does not raise exception when valid reference" do
      %w(ABC1234+01 ABC1234-01).each do |string|
        expect {
          LoanReference.new(string)
        }.not_to raise_error
      end
    end
  end

  it 'possible reference characters and numbers, before version number, do not include 1, 0, I or O' do
    %w(1 0 I O).each do |char|
      expect(LoanReference::LETTERS_AND_NUMBERS).not_to include(char)
    end
  end

  describe '#generate' do
    let(:loan) { FactoryGirl.build(:loan) }

    it "should return reference in format {letters/numbers}{separator}{version number}" do
      expect(LoanReference.generate).to match(/\A[\dA-Z]{7}\+\d{2}\z/)
    end

    it "should not end in E+{numbers}" do
      LoanReference.stub(:random_string).and_return('AABBCCE', 'DDEEFFE', 'ABCDEFG')

      expect(LoanReference.generate).to eq('ABCDEFG+01')
    end
  end

  describe "#increment" do
    let(:loan_reference) { LoanReference.new('ABCDEFG+01') }

    it "should return incremented loan reference" do
      expect(loan_reference.increment).to eq('ABCDEFG+02')
    end

    it "should increment loan reference into double digits" do
      loan_reference = LoanReference.new('ABCDEFG+09')

      expect(loan_reference.increment).to eq('ABCDEFG+10')
    end

    it "should not increment loan reference repeatedly" do
      reference = nil

      2.times { reference = loan_reference.increment }

      expect(reference).to eq('ABCDEFG+02')
    end
  end

end