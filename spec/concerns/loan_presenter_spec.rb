require 'spec_helper'

describe LoanPresenter do
  let(:klass) do
    Class.new do
      include LoanPresenter

      attribute :name
      attribute :address, read_only: true
    end
  end

  let(:loan) { double(Loan) }
  let(:transition) { klass.new(loan) }

  describe "ActiveModel conformance" do
    it "persisted? should be false" do
      expect(transition).not_to be_persisted
    end

    it "should include ActiveModel::Conversion" do
      expect(klass.ancestors).to include(ActiveModel::Conversion)
    end

    it "should extend ActiveModel::Naming" do
      expect(klass.singleton_class.ancestors).to include(ActiveModel::Naming)
    end
  end

  describe "#initialize" do
    it "should take a loan" do
      transition = klass.new(loan)
      expect(transition.loan).to eq(loan)
    end
  end

  describe "attribute delegation" do
    context "read write attributes" do
      it "should delegate the reader to the loan" do
        expect(loan).to receive(:name).and_return('Name')

        expect(transition.name).to eq('Name')
      end

      it "should delegate the writer to the loan" do
        expect(loan).to receive(:name=).with('NewName')

        transition.name = 'NewName'
      end
    end

    context "read only attribute" do
      it "should not have a writer" do
        expect(transition).not_to respond_to(:address=)
      end
    end
  end

  describe "#attributes=" do
    it "should call the writers for defined attributes" do
      expect(transition).to receive(:name=).with('Name')

      transition.attributes = {'name' => 'Name'}
    end

    it "should not call methods for read only attributes" do
      expect(transition).not_to receive(:address=)

      transition.attributes = {'address' => 'address'}
    end

    it "should not call methods for undefined attributes" do
      expect(transition).not_to receive(:junk=)

      transition.attributes = {'junk' => 'junk'}
    end
  end

  describe "#save" do
    it "should delegate to loan" do
      expect(loan).to receive(:transaction).and_yield
      expect(loan).to receive(:save!).and_return(true)

      expect(transition.save).to eq(true)
    end
  end
end
