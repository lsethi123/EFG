shared_examples_for 'loan presenter that validates loan repayment frequency' do

  context "when repaying loan quarterly" do
    it "should require repayment duration to be divisible by 3" do
      loan_presenter.repayment_frequency_id = 3
      loan_presenter.repayment_duration = 19
      expect(loan_presenter).not_to be_valid

      loan_presenter.repayment_duration = 18
      expect(loan_presenter).to be_valid
    end
  end

  context "when repaying loan six monthly" do
    it "should require repayment duration to be divisible by 6" do
      loan_presenter.repayment_frequency_id = 2
      loan_presenter.repayment_duration = 11
      expect(loan_presenter).not_to be_valid

      loan_presenter.repayment_duration = 12
      expect(loan_presenter).to be_valid
    end
  end

  context "when repaying loan annually" do
    it "should require repayment duration to be divisible by 12" do
      loan_presenter.repayment_frequency_id = 1
      loan_presenter.repayment_duration = 25
      expect(loan_presenter).not_to be_valid

      loan_presenter.repayment_duration = 24
      expect(loan_presenter).to be_valid
    end
  end

end
