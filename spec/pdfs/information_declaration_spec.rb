# encoding: utf-8

require 'spec_helper'

describe InformationDeclaration do
  let(:lender) { FactoryGirl.create(:lender, name: 'Lender') }
  let!(:sic) { FactoryGirl.create(:sic_code, code: 'A10.1.2', description: 'Foo', state_aid_threshold: 15000) }
  let(:loan) {
    FactoryGirl.create(:loan, :completed, lender: lender,
      amount: Money.new(12_345_67),
      business_name: 'ACME',
      company_registration: 'B1234567890',
      legal_form_id: 2,
      loan_category_id: LoanCategory::TypeE.id,
      loan_sub_category_id: 1,
      maturity_date: Date.new(2020, 3, 2),
      postcode: 'ABC 123',
      previous_borrowing: false,
      reason_id: 17,
      reference: 'QWERTY+01',
      repayment_duration: { months: 54 },
      repayment_frequency_id: 3,
      sic_code: 'A10.1.2',
      sic_desc: 'Foo',
      state_aid: Money.new(1_234_56, 'EUR'),
      trading_date: Date.new(1999, 1, 1),
      trading_name: 'ACME Trading',
      turnover: Money.new(5_000_000_00)
    )
  }

  let(:pdf_document) {
    information_declaration = InformationDeclaration.new(loan)
    PDF::Reader.new(StringIO.new(information_declaration.render))
  }

  let(:pdf_content) {
    # Note: replace line breaks to make assertions easier
    pdf_document.pages.collect { |page| page.to_s }.join(" ").gsub("\n", ' ')
  }

  let(:page_count) { pdf_document.pages.size }

  before do
    # PDF table output gets a jumbled up with long lines of text
    # so stub LoanCategory#name to be short enough to test
    fake_loan_category = LoanCategory.new.tap { |c| c.id = 1; c.name = "Category Name" }
    allow_any_instance_of(Loan).to receive(:loan_category).and_return(fake_loan_category)
  end

  describe "#render" do

    it "should contain a header" do
      expect(pdf_content).to include('Information Declaration')
      expect(pdf_content).to include("Lender organisation:Lender")
      expect(pdf_content).to include("Business name:ACME")
      expect(pdf_content).to include("EFG/SFLG reference:QWERTY+01")
      expect(pdf_content).to include("Loan amount:£12,345.67")
    end

    it "should contain loan details" do
      expect(pdf_content).to include('QWERTY+01')
      expect(pdf_content).to include('ACME')
      expect(pdf_content).to include('ACME Trading')
      expect(pdf_content).to include('Partnership')
      expect(pdf_content).to include('B1234567890')
      expect(pdf_content).to include('£5,000,000.00')
      expect(pdf_content).to include('01-01-1999')
      expect(pdf_content).to include('ABC 123')
      expect(pdf_content).to include('£12,345.67')
      expect(pdf_content).to include('4 years, 6 months')
      expect(pdf_content).to include('Quarterly')
      expect(pdf_content).to include('A10.1.2')
      expect(pdf_content).to include('Foo')
      expect(pdf_content).to include("Category Name")
      expect(pdf_content).to include("Overdrafts")
      expect(pdf_content).to include('Equipment purchase')
      expect(pdf_content).to include('No')
      expect(pdf_content).to include('€1,234.56')
      expect(pdf_content).to include('Yes')
    end

    it "should contain declaration text" do
      expect(pdf_content).to include(I18n.t('pdfs.information_declaration.declaration').gsub("\n", ''))
      expect(pdf_content).to include(I18n.t('pdfs.information_declaration.declaration_list').gsub("\n", ''))
      expect(pdf_content).to include(I18n.t('pdfs.information_declaration.declaration_important').gsub(/<\/?\w+>/, ''))
    end

    it "should contain signature text" do
      expect(pdf_content.scan(/Signed________/).size).to eq(4)
      expect(pdf_content.scan(/Print name________/).size).to eq(4)
      expect(pdf_content.scan(/Position________/).size).to eq(4)
      expect(pdf_content.scan(/Date________/).size).to eq(4)

      expect(pdf_content).to include(I18n.t('pdfs.information_declaration.signatories'))
    end

    it "should contain page numbers" do
      page_count.times do |num|
        expect(pdf_content).to include("Page: #{num + 1} of #{page_count}")
      end
    end

    it "should contain loan reference on every page" do
      expect(pdf_content.scan("Loan: QWERTY+01").size).to eq(page_count)
    end

  end

end
