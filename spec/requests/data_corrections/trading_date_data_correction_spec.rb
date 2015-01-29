require 'spec_helper'

describe 'Trading Date Data Correction' do
  it_behaves_like 'a basic data correction', :trading_date, '01/10/14', Date.new(2014,10,1)
end
