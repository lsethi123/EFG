module Sequenceable
  extend ActiveSupport::Concern

  included do
    before_validation :set_seq, on: :create
  end

  protected

  # use #base_class to ensure seq is unique when using STI
  # e.g. InitialDrawChange, LoanChange
  def set_seq
    self.seq = (self.class.base_class.where(loan_id: loan_id).maximum(:seq) || -1) + 1
  end

end
