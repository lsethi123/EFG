class DataCorrectionsController < ApplicationController
  TYPES = {
    'business_name' => BusinessNameDataCorrection,
    'company_registration' => CompanyRegistrationDataCorrection,
    'demanded_amount' => DemandedAmountDataCorrection,
    'generic_fields' => GenericFieldsDataCorrection,
    'lender_reference' => LenderReferenceDataCorrection,
    'postcode' => PostcodeDataCorrection,
    'sortcode' => SortcodeDataCorrection,
    'sub_lender' => SubLenderDataCorrection,
    'trading_date' => TradingDateDataCorrection,
    'trading_name' => TradingNameDataCorrection,
  }

  before_filter :verify_create_permission
  before_filter :load_loan

  def index
  end

  def new
    @presenter = presenter_class.new(@loan, current_user)
  end

  def create
    @presenter = presenter_class.new(@loan, current_user)
    @presenter.attributes = params[:data_correction]

    if @presenter.save
      redirect_to loan_url(@loan)
    else
      @loan.reload
      render :new
    end
  end

  private
    def load_loan
      @loan = current_lender.loans.correctable.find(params[:loan_id])
    end

    def presenter_class
      TYPES.fetch(params[:type])
    end

    def verify_create_permission
      enforce_create_permission(DataCorrection)
    end
end
