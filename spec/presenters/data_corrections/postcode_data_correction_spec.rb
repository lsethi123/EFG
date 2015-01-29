require 'spec_helper'

describe PostcodeDataCorrection do
  it_behaves_like 'a basic data correction presenter', :postcode, 'EC1A 9PN'
end
