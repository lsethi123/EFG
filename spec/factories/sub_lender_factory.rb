FactoryGirl.define do
  factory :sub_lender do
    lender
    sequence(:name) { |n| "Sub-lender #{n}" }
  end
end
