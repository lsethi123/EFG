class SubLendersController < ApplicationController
  include AuditableController

  before_filter :load_lender

  def index
    @sub_lenders = @lender.sub_lenders
  end

  def new
    @sub_lender = @lender.sub_lenders.new
  end

  def create
    @sub_lender = @lender.sub_lenders.new
    @sub_lender.attributes = params[:sub_lender]

    save = -> { @sub_lender.save }

    if audit(AdminAudit::SubLenderCreated, @sub_lender, &save)
      redirect_to lender_sub_lenders_url(@lender)
    else
      render :new
    end
  end

  def edit
    @sub_lender = @lender.sub_lenders.find(params[:id])
  end

  def update
    @sub_lender = @lender.sub_lenders.find(params[:id])
    @sub_lender.attributes = params[:sub_lender].slice(:name)

    save = -> { @sub_lender.save }

    if audit(AdminAudit::SubLenderEdited, @sub_lender, &save)
      redirect_to lender_sub_lenders_url(@lender)
    else
      render :edit
    end
  end

  def destroy
    @sub_lender = @lender.sub_lenders.find(params[:id])
    @sub_lender.destroy
    redirect_to lender_sub_lenders_url(@lender)
  end

  private

  def load_lender
    @lender = Lender.find(params[:lender_id])
  end

end
