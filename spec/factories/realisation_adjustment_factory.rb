FactoryGirl.define do
  factory :realisation_adjustment do
    created_by factory: :cfe_user
    amount Money.new(100_00)
    date { Date.current }

    after(:build) do |realisation_adjustment|
      realisation_adjustment.loan ||= FactoryGirl.create(:loan, :realised)
    end
  end
end
