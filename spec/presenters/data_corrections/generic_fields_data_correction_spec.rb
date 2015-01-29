require 'spec_helper'

describe GenericFieldsDataCorrection do

  let(:loan_with_generic_info) { FactoryGirl.create(:loan, :guaranteed, :loan_with_generic_info) }
  let(:loan_without_generic_info) { FactoryGirl.create(:loan, :guaranteed, :loan_without_generic_info) }

  describe 'validations' do

    it 'has a valid factory' do
      presenter = FactoryGirl.build(:generic_fields_data_correction, loan: loan_with_generic_info)
      presenter.should be_valid
    end

    it "requires at least one generic field to be entered" do
      presenter = FactoryGirl.build(:generic_fields_data_correction, loan: loan_without_generic_info)
      presenter.generic1 = nil
      presenter.generic2 = nil
      presenter.generic3 = nil
      presenter.generic4 = nil
      presenter.generic5 = nil
      presenter.should_not be_valid
      presenter.errors[:base].should_not be_empty
    end
  end

  describe '#save' do
    let!(:old_generic_value_1) { loan.generic1 }
    let!(:old_generic_value_2) { loan.generic2 }
    let!(:old_generic_value_3) { loan.generic3 }
    let!(:old_generic_value_4) { loan.generic4 }
    let!(:old_generic_value_5) { loan.generic5 }

    let(:user) { FactoryGirl.create(:lender_user) }

    let!(:presenter) { FactoryGirl.build(:generic_fields_data_correction, loan: loan, created_by: user) }

    context 'success' do
      let!(:loan) { loan_with_generic_info }

      let!(:new_generic_value_1) { "our reference ab12" }
      let!(:new_generic_value_2) { "authorized" }
      let!(:new_generic_value_3) { "important loan info" }
      let!(:new_generic_value_4) { "entered by jeff" }
      let!(:new_generic_value_5) { "loan reference: 12345" }

      it 'creates a DataCorrection and updates the loan' do
        presenter.generic1 = new_generic_value_1
        presenter.generic2 = new_generic_value_2
        presenter.generic3 = new_generic_value_3
        presenter.generic4 = new_generic_value_4
        presenter.generic5 = new_generic_value_5

        presenter.save.should == true

        data_correction = loan.data_corrections.last!
        data_correction.created_by.should == user
        data_correction.change_type.should == ChangeType::GenericFields

        data_correction.old_generic1.should == old_generic_value_1
        data_correction.old_generic2.should == old_generic_value_2
        data_correction.old_generic3.should == old_generic_value_3
        data_correction.old_generic4.should == old_generic_value_4
        data_correction.old_generic5.should == old_generic_value_5

        data_correction.generic1.should == new_generic_value_1
        data_correction.generic2.should == new_generic_value_2
        data_correction.generic3.should == new_generic_value_3
        data_correction.generic4.should == new_generic_value_4
        data_correction.generic5.should == new_generic_value_5

        loan.reload

        loan.generic1.should == new_generic_value_1
        loan.generic2.should == new_generic_value_2
        loan.generic3.should == new_generic_value_3
        loan.generic4.should == new_generic_value_4
        loan.generic5.should == new_generic_value_5
        loan.modified_by.should == user
      end
    end

    context 'failure' do
      let!(:loan) { loan_without_generic_info }

      it 'does not update loan' do
        presenter.generic1 = nil
        presenter.generic2 = nil
        presenter.generic3 = nil
        presenter.generic4 = nil
        presenter.generic5 = nil

        presenter.save.should == false
        loan.reload

        loan.generic1.should == old_generic_value_1
        loan.generic2.should == old_generic_value_2
        loan.generic3.should == old_generic_value_3
        loan.generic4.should == old_generic_value_4
        loan.generic5.should == old_generic_value_5
      end
    end

  end

end
