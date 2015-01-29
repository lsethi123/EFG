require 'spec_helper'

describe SortcodeDataCorrection do
  it_behaves_like 'a basic data correction presenter', :sortcode, '654321'
end
