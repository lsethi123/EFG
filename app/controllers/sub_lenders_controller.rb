class SubLendersController < ApplicationController

  before_filter :load_lender

  def index
    @sub_lenders = @lender.sub_lenders
  end

  private

  def load_lender
    @lender = Lender.find(params[:lender_id])
  end

end
