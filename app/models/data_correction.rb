class DataCorrection < ActiveRecord::Base
  include FormatterConcern
  include Sequenceable

  Formatters = {
    dti_demand_outstanding: MoneyFormatter.new,
    dti_interest: MoneyFormatter.new,
    dti_amount_claimed: MoneyFormatter.new,
    facility_letter_date: SerializedDateFormatter,
    postcode: PostcodeFormatter,
    trading_date: SerializedDateFormatter,
  }

  belongs_to :created_by, class_name: 'User'
  belongs_to :loan

  validates_presence_of :loan, strict: true
  validates_presence_of :change_type_id, strict: true
  validates_presence_of :created_by, strict: true
  validates_presence_of :date_of_change
  validates_presence_of :modified_date, strict: true

  serialize :data_correction_changes, JSON

  def change_type
    ChangeType.find(change_type_id)
  end

  def change_type=(change_type)
    self.change_type_id = change_type.id
  end

  def change_type_name
    change_type.name
  end

  def old_lending_limit
    get_lending_limit(:first)
  end

  def lending_limit
    get_lending_limit(:last)
  end

  def data_correction_changes=(changes)
    changes.each do |(key, values)|
      formatter = Formatters.fetch(key.to_sym, DefaultFormatter)
      changes[key][1] = formatter.parse(values.last)
    end
    super(changes)
  end

  def data_correction_changes
    @corrections ||= correction_details
  end

  private

  def get_lending_limit(first_or_last)
    limit_id = data_correction_changes['lending_limit_id'].try(first_or_last)
    LendingLimit.find_by_id(limit_id)
  end

  def correction_details
    corrections = (read_attribute(:data_correction_changes) || {})
    corrections.each_with_object({}) do |(key, values), memo|
      formatter = Formatters.fetch(key.to_sym, DefaultFormatter)

      memo[key] = [
        formatter.format(values.first),
        formatter.format(values.last)
      ]
    end
  end

  def method_missing(method, *args, &block)
    is_old = method.to_s.start_with?('old_')
    change_key = method.to_s.sub(/^old_/, '')

    if data_correction_changes.has_key?(change_key)
      values = data_correction_changes[change_key]
      is_old ? values.first : values.last
    else
      super
    end
  end

end
