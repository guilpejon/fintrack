class ExpensesController < ApplicationController
  before_action :set_expense, only: %i[edit update destroy]

  def index
    @expenses = current_user.expenses
      .includes(:category, :credit_card)
      .for_month(@current_date)
      .ordered

    @pagy, @expenses = pagy(@expenses, limit: 20)
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @total = current_user.expenses.for_month(@current_date).sum(:amount)
  end

  def new
    @expense = current_user.expenses.build(date: Date.current, expense_type: "variable")
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
    @quick = params[:quick].present?
  end

  def create
    @expense = current_user.expenses.build(expense_params)

    if @expense.save
      redirect_to expenses_path, notice: "Expense added."
    else
      @categories = current_user.categories.order(:name)
      @credit_cards = current_user.credit_cards.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
  end

  def update
    if @expense.update(expense_params)
      redirect_to expenses_path, notice: "Expense updated."
    else
      @categories = current_user.categories.order(:name)
      @credit_cards = current_user.credit_cards.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    respond_to do |format|
      format.html { redirect_to expenses_path, notice: "Expense deleted." }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("expense_#{@expense.id}") }
    end
  end

  private

  def set_expense
    @expense = current_user.expenses.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(:description, :amount, :date, :expense_type, :category_id, :credit_card_id, :recurring, :recurrence_day)
  end
end
