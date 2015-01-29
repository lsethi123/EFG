class LoanModification < ActiveRecord::Base
  include FormatterConcern
  include Sequenceable

  belongs_to :created_by, class_name: 'User'
  belongs_to :loan

  validates_presence_of :loan, strict: true
  validates_presence_of :created_by, strict: true
  validates_presence_of :date_of_change
  validates_presence_of :modified_date, strict: true

  format :amount, with: MoneyFormatter.new
  format :amount_drawn, with: MoneyFormatter.new
  format :date_of_change, with: QuickDateFormatter
  format :initial_draw_amount, with: MoneyFormatter.new
  format :initial_draw_date, with: QuickDateFormatter
  format :lump_sum_repayment, with: MoneyFormatter.new
  format :maturity_date, with: QuickDateFormatter
  format :modified_date, with: QuickDateFormatter
  format :old_amount, with: MoneyFormatter.new
  format :old_initial_draw_amount, with: MoneyFormatter.new
  format :old_initial_draw_date, with: QuickDateFormatter
  format :old_maturity_date, with: QuickDateFormatter

  def change_type
    ChangeType.find(change_type_id)
  end

  def change_type=(change_type)
    self.change_type_id = change_type.id
  end

  def change_type_name
    change_type.name
  end
end
