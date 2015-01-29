class ChangeType < StaticAssociation
  self.data = [
    { id: '1', name: 'Business name' },
    { id: '2', name: 'Capital repayment holiday' },
    { id: '3', name: 'Change repayments' },
    { id: '4', name: 'Extend term' },
    { id: '5', name: 'Lender demand satisfied' },
    { id: '6', name: 'Lump sum repayment' },
    { id: '7', name: 'Record agreed draw' },
    { id: '8', name: 'Reprofile draws' },
    { id: '9', name: 'Data correction' },
    { id: 'a', name: 'Decrease term' },
    { id: 'b', name: 'Repayment frequency' },
    { id: 'c', name: 'Postcode' },
    { id: 'd', name: 'Lender Reference' },
    { id: 'e', name: 'Trading Name' },
    { id: 'f', name: 'Sortcode' },
    { id: 'g', name: 'Trading Date' },
    { id: 'h', name: 'Company Registration' },
    { id: 'i', name: 'Generic Fields' },
  ]

  BusinessName = find('1')
  CapitalRepaymentHoliday = find('2')
  ChangeRepayments = find('3')
  ExtendTerm = find('4')
  LenderDemandSatisfied = find('5')
  LumpSumRepayment = find('6')
  RecordAgreedDraw = find('7')
  ReprofileDraws = find('8')
  DataCorrection = find('9')
  DecreaseTerm = find('a')
  RepaymentFrequency = find('b')
  Postcode = find('c')
  LenderReference = find('d')
  TradingName = find('e')
  Sortcode = find('f')
  TradingDate = find('g')
  CompanyRegistration = find('h')
  GenericFields = find('i')
end
