require 'spec_helper'

describe TradingDateDataCorrection do
  it_behaves_like 'a basic data correction presenter', :trading_date, '01/10/14', Date.new(2014,10,1)
end