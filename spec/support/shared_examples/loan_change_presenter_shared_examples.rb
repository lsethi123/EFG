shared_examples_for 'LoanChangePresenter' do
  describe 'validations' do
    let(:factory_name) { described_class.name.tableize.singularize }
    let(:factory_options) { respond_to?(:presenter_factory_options) ? presenter_factory_options : {} }
    let(:presenter) { FactoryGirl.build(factory_name, factory_options) }

    it 'has a valid factory' do
      presenter.should be_valid
    end

    it 'requires a date_of_change' do
      presenter.date_of_change = nil
      presenter.should_not be_valid
    end
  end
end
