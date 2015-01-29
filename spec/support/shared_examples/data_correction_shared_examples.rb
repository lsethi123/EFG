shared_examples_for 'a basic data correction' do |attribute, input_value, new_value = nil|
  include DataCorrectionSpecHelper

  let(:loan) { FactoryGirl.create(:loan, :guaranteed, legal_form_id: 4, lender: current_user.lender) }
  let!(:old_value) { loan.public_send(attribute) }
  let(:expected_new_value) { new_value || input_value }

  before do
    visit_data_corrections
    click_link attribute.to_s.titleize
  end

  it do
    fill_in attribute, input_value
    click_button 'Submit'

    data_correction = loan.data_corrections.last!
    data_correction.change_type.should == "ChangeType::#{attribute.to_s.classify}".constantize
    data_correction.created_by.should == current_user
    data_correction.date_of_change.should == Date.current
    data_correction.modified_date.should == Date.current
    data_correction.public_send("old_#{attribute}").should == old_value
    data_correction.public_send(attribute).should == expected_new_value

    loan.reload
    loan.public_send(attribute).should == expected_new_value
    loan.modified_by.should == current_user
  end

  it 'with no input' do
    click_button 'Submit'

    loan.reload
    loan.modified_by.should_not eql(current_user)
  end
end

shared_examples_for 'a basic data correction presenter' do |attribute, input_value, new_value = nil, loan_attrs = {}|
  let(:factory_name) { "#{attribute}_data_correction" }
  let(:user) { FactoryGirl.create(:lender_user) }
  let(:loan) { FactoryGirl.create(:loan, :guaranteed, loan_attrs) }
  let(:presenter) { FactoryGirl.build(factory_name, created_by: user, loan: loan) }
  let(:expected_new_value) { new_value || input_value }

  describe 'validations' do
    let(:presenter) { FactoryGirl.build(factory_name, loan: loan) }

    it 'has a valid factory' do
      presenter.should be_valid
    end

    it "requires a #{attribute}" do
      presenter.public_send("#{attribute}=", '')
      presenter.should_not be_valid
    end

    it "new #{attribute} value must not be the same as old value" do
      presenter.public_send("#{attribute}=", loan.public_send(attribute))
      presenter.should_not be_valid
    end
  end

  it_behaves_like "loan updating data correction presenter", attribute, input_value, new_value, loan_attrs

end

shared_examples_for "loan updating data correction presenter" do |attribute, input_value, new_value = nil, loan_attrs = {}|
  let(:factory_name) { "#{attribute}_data_correction" }
  let(:user) { FactoryGirl.create(:lender_user) }
  let(:loan) { FactoryGirl.create(:loan, :guaranteed, loan_attrs) }
  let(:presenter) { FactoryGirl.build(factory_name, created_by: user, loan: loan) }
  let(:expected_new_value) { new_value || input_value }

  describe '#save' do
    let!(:old_value) { loan.public_send(attribute) }

    context 'success' do
      it 'creates a DataCorrection and updates the loan' do
        presenter.public_send("#{attribute}=", input_value)
        presenter.save.should == true

        data_correction = loan.data_corrections.last!
        data_correction.created_by.should == user
        data_correction.change_type.should == "ChangeType::#{attribute.to_s.classify}".constantize
        data_correction.public_send("old_#{attribute}").should == old_value
        data_correction.public_send(attribute).should == expected_new_value

        loan.reload
        loan.public_send(attribute).should == expected_new_value
        loan.modified_by.should == user
      end
    end

    context 'failure' do
      it 'does not update loan' do
        presenter.public_send("#{attribute}=", nil)
        presenter.save.should == false
        loan.reload

        loan.public_send(attribute).should == old_value
      end
    end
  end
end
