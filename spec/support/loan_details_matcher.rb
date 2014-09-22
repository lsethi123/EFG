RSpec::Matchers.define :have_detail_row do |name, value|
  match do |page|
    expect(page).to have_xpath("//tr[th[text()='#{name}']][td[text()='#{value}']]")
  end
end
