require 'spec_helper'

describe LenderReferenceDataCorrection do
  it_behaves_like 'a basic data correction presenter', :lender_reference, 'Bar'
end
