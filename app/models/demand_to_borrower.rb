class DemandToBorrower < ActiveRecord::Base
  include FormatterConcern
  include Sequenceable

  belongs_to :created_by, class_name: 'User'
  belongs_to :loan

  validates_presence_of :created_by, strict: true
  validates_presence_of :loan, strict: true
  validates_presence_of :modified_date, strict: true
  validates_presence_of :date_of_demand
  validates_presence_of :demanded_amount

  format :date_of_demand, with: QuickDateFormatter
  format :demanded_amount, with: MoneyFormatter.new

end
