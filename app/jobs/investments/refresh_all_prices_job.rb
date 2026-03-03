module Investments
  class RefreshAllPricesJob < ApplicationJob
    queue_as :default

    def perform
      Investment.where.not(ticker: [ nil, "" ])
                .distinct
                .pluck(:ticker, :investment_type)
                .each { |ticker, type| FetchPriceJob.perform_later(ticker, type) }
    rescue StandardError => e
      Rails.logger.error "Investments::RefreshAllPricesJob error: #{e.message}"
    end
  end
end
