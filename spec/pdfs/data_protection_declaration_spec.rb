# encoding: utf-8

require 'spec_helper'

describe DataProtectionDeclaration do

  let(:loan) { FactoryGirl.create(:loan, :offered) }

  let(:pdf_content) {
    data_protection_declaration = DataProtectionDeclaration.new
    reader = PDF::Reader.new(StringIO.new(data_protection_declaration.render))
    # Note: replace line breaks to make assertions easier
    reader.pages.collect { |page| page.to_s }.join(" ").gsub("\n", ' ')
  }

  describe "#render" do

    it "should contain a title" do
      expect(pdf_content).to include(I18n.t('pdfs.data_protection.title').upcase)
    end

    it "should contain body text" do
      expect(pdf_content).to include(I18n.t('pdfs.data_protection.declaration'))
      expect(pdf_content).to include(I18n.t('pdfs.data_protection.declaration_list').gsub("\n", ''))
    end

    it "should contain signature text" do
      expect(pdf_content.scan(/Signed________/).size).to eq(4)
      expect(pdf_content.scan(/Print name________/).size).to eq(4)
      expect(pdf_content.scan(/Position________/).size).to eq(4)
      expect(pdf_content.scan(/Date________/).size).to eq(4)

      expect(pdf_content).to include(I18n.t('pdfs.data_protection.signatories'))
    end

  end

end
