class RealisationAdjustment < ActiveRecord::Base
  include FormatterConcern

  belongs_to :loan
  belongs_to :created_by, class_name: 'User'

  format :amount, with: MoneyFormatter.new
  format :date, with: QuickDateFormatter

  validates_presence_of :created_by, strict: true
  validates_presence_of :date
  validates_presence_of :loan, strict: true

  validate do
    errors.add(:amount, :greater_than, count: 0) unless amount && amount.cents > 0
  end

  attr_accessible :amount, :date, :notes
end
