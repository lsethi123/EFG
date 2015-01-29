module LoanChangesHelper

  def capital_repayment_holiday_link(loan)
    if loan.fully_drawn?
      link_to('Capital Repayment Holiday', new_loan_loan_change_path(@loan, type: 'capital_repayment_holiday'))
    else
      content_tag(:span, 'Capital Repayment Holiday', class: 'not-available') +
        content_tag(:em, ' - (Only applicable to fully drawn loans)')
    end
  end

  def premium_schedule_hidden_fields(hash)
    if hash.is_a?(Hash)
      %w(
        premium_cheque_month
        initial_draw_amount
        repayment_duration
        initial_capital_repayment_holiday
        second_draw_amount
        second_draw_months
        third_draw_amount
        third_draw_months
        fourth_draw_amount
        fourth_draw_months
      ).collect do |field|
        hidden_field_tag "premium_schedule[#{field}]", hash[field.to_sym]
      end.join.html_safe
    end
  end

  def reprofile_draws_link(loan)
    unless loan.fully_drawn?
      link_to('Reprofile Draws', new_loan_loan_change_path(@loan, type: 'reprofile_draws'))
    else
      content_tag(:span, 'Reprofile Draws', class: 'not-available') +
        content_tag(:em, ' - (Not applicable as loan is fully drawn)')
    end
  end

end
