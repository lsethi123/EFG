require 'spec_helper'

describe 'Lender Reference Data Correction' do
  it_behaves_like 'a basic data correction', :lender_reference, 'NEW REFERENCE'
end
