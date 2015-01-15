class SubLender < ActiveRecord::Base

  attr_accessible :name

  belongs_to :lender

end
