class InvestmentsController < ApplicationController
  before_action :set_investment, only: %i[edit update destroy refresh_price]

  def index
    @investments = current_user.investments.order(:investment_type, :name)

    @total_invested = @investments.sum { |i| i.total_invested }
    @current_value = @investments.sum { |i| i.current_value }
    @total_pnl = @current_value - @total_invested
    @total_pnl_percent = @total_invested.positive? ? (@total_pnl / @total_invested * 100).round(2) : 0

    @by_type = @investments.group_by(&:investment_type)
  end

  def new
    @investment = current_user.investments.build(
      investment_type: "stock",
      currency: "BRL",
      quantity: 0,
      average_price: 0,
      current_price: 0
    )
  end

  def create
    @investment = current_user.investments.build(investment_params)

    if @investment.save
      Investments::FetchPriceJob.perform_later(@investment.ticker, @investment.investment_type) if @investment.ticker.present?
      redirect_to investments_path, notice: t("controllers.investments.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @investment.update(investment_params)
      redirect_to investments_path, notice: t("controllers.investments.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @investment.destroy
    redirect_to investments_path, notice: t("controllers.investments.destroyed")
  end

  PRICE_FRESHNESS_WINDOW = 1.hour

  def refresh_price
    if @investment.last_price_update_at&.> PRICE_FRESHNESS_WINDOW.ago
      redirect_to investments_path, notice: t("controllers.investments.price_already_fresh", name: @investment.name)
    else
      Investments::FetchPriceJob.perform_later(@investment.ticker, @investment.investment_type)
      redirect_to investments_path, notice: t("controllers.investments.price_queued_single", name: @investment.name)
    end
  end

  def refresh_all_prices
    stale = current_user.investments
                        .where.not(ticker: [ nil, "" ])
                        .where("last_price_update_at IS NULL OR last_price_update_at < ?", PRICE_FRESHNESS_WINDOW.ago)
                        .pluck(:ticker, :investment_type).uniq

    if stale.empty?
      redirect_to investments_path, notice: t("controllers.investments.prices_already_fresh")
    else
      stale.each { |ticker, type| Investments::FetchPriceJob.perform_later(ticker, type) }
      redirect_to investments_path, notice: t("controllers.investments.price_queued_all")
    end
  end

  private

  def set_investment
    @investment = current_user.investments.find(params[:id])
  end

  def investment_params
    params.require(:investment).permit(:name, :ticker, :investment_type, :quantity, :average_price, :current_price, :currency)
  end
end
