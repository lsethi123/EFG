class TrancheDrawdown
  attr_reader :amount, :month

  def initialize(amount, month)
    @amount = amount || Money.new(0)
    @month  = month
  end
end
