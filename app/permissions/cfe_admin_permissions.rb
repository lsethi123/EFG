module CfeAdminPermissions
  def can_create?(resource)
    [
      AuditorUser,
      CfeUser,
      Lender,
      LenderAdmin,
      LendingLimit,
      Phase,
      PremiumCollectorUser,
      SubLender,
    ].include?(resource)
  end

  def can_destroy?(resource)
    [
      SubLender,
    ].include?(resource)
  end

  def can_update?(resource)
    [
      AuditorUser,
      CfeUser,
      Lender,
      LenderAdmin,
      LendingLimit,
      Phase,
      PremiumCollectorUser,
      SubLender,
    ].include?(resource)
  end

  def can_enable?(resource)
    can_update?(resource)
  end

  def can_disable?(resource)
    can_update?(resource)
  end

  def can_unlock?(resource)
    can_update?(resource)
  end

  def can_view?(resource)
    [
      AuditorUser,
      CfeUser,
      Expert,
      Lender,
      LenderAdmin,
      LendingLimit,
      Phase,
      PremiumCollectorUser,
      SubLender,
    ].include?(resource)
  end
end
