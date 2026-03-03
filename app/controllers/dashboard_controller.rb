class DashboardController < ApplicationController
  def index
    @incomes = current_user.incomes.for_month(@current_date)
    @expenses = current_user.expenses.for_month(@current_date).includes(:category, :credit_card)

    @total_income = @incomes.sum(:amount)
    @total_expenses = @expenses.sum(:amount)
    @net_balance = @total_income - @total_expenses

    # Credit card bills this month
    @credit_cards = current_user.credit_cards.includes(:expenses)
    @total_card_bills = @credit_cards.sum { |card| card.current_bill(@current_date) }

    # Spending by category for donut chart
    raw_spending = @expenses
      .joins(:category)
      .group("categories.name")
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(8)
      .to_h

    category_color_map = current_user.categories.pluck(:name, :color).to_h
    @spending_colors = raw_spending.keys.map { |name| category_color_map[name] || "#6C63FF" }
    @spending_by_category = raw_spending.transform_keys { |name| I18n.t("category_names.#{name}", default: name) }

    # Spending by payee for donut chart
    @spending_by_payee = @expenses
      .joins(:payee)
      .group("payees.name")
      .sum(:amount)
      .sort_by { |_, v| -v }
      .first(8)
      .to_h

    payee_palette = %w[#6C63FF #00D4AA #FF6B6B #F7B731 #A78BFA #34D399 #60A5FA #F472B6]
    @spending_by_payee_colors = payee_palette.first(@spending_by_payee.size)

    # Monthly cash flow for last 6 months (bar chart)
    @monthly_income = current_user.incomes
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    @monthly_expenses = current_user.expenses
      .where(date: 6.months.ago.beginning_of_month..Date.current.end_of_month)
      .group_by_month(:date, format: "%b %Y")
      .sum(:amount)

    # Bank accounts total balance
    @total_bank_balance = current_user.bank_accounts.sum(:balance)

    # Possessions total current value
    @total_possessions_value = current_user.possessions.sum(:current_value)

    # Recent transactions
    @recent_transactions = current_user.expenses
      .includes(:category)
      .order(date: :desc, created_at: :desc)
      .limit(5)
  end
end
