class Phase < StaticAssociation
  self.data = [
    { id: 1, euro_conversion_rate: BigDecimal.new('1.04058'), starts_on: Date.new(2009, 1, 14), ends_on: Date.new(2010, 3, 31) },
    { id: 2, euro_conversion_rate: BigDecimal.new('1.04058'), starts_on: Date.new(2010, 4, 1),  ends_on: Date.new(2011, 3, 31) },
    { id: 3, euro_conversion_rate: BigDecimal.new('1.04058'), starts_on: Date.new(2011, 4, 1),  ends_on: Date.new(2012, 3, 31) },
    { id: 4, euro_conversion_rate: BigDecimal.new('1.19740'), starts_on: Date.new(2012, 4, 1),  ends_on: Date.new(2013, 3, 31) },
    { id: 5, euro_conversion_rate: BigDecimal.new('1.22850'), starts_on: Date.new(2013, 4, 1),  ends_on: Date.new(2014, 3, 31) },
    { id: 6, euro_conversion_rate: BigDecimal.new('1.20744'), starts_on: Date.new(2014, 4, 1),  ends_on: Date.new(2015, 3, 31) }
  ]

  def lending_limits
    LendingLimit.where(phase_id: id)
  end

  def name
    "Phase #{id} (#{financial_year})"
  end

  def rules
    "Phase#{id}Rules".constantize
  end

  private

  # The financial year for which the Phase operates for. Phase 1 is slightly
  # different, starting on 2009-01-14, but it was deemed for consistency that
  # it was acceptable to display it as FY 2009/10.
  def financial_year
    "FY #{starts_on.strftime('%Y')}/#{ends_on.strftime('%y')}"
  end

  def type
    LoanTypes::EFG
  end
end
