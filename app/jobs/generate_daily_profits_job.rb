class GenerateDailyProfitsJob < ApplicationJob
  queue_as :default

  def perform(profit_date: Date.current)
    Investment.active.find_each do |investment|
      process_investment(investment, profit_date)
    rescue StandardError => e
      log_unexpected_failure(investment, e)
    end
  end

  private

  def process_investment(investment, profit_date)
    result = GenerateDailyProfitService.new(investment, profit_date).call

    if result.success?
      log_success(investment, result.profit_record)
    else
      log_skip_or_failure(investment, result.error)
    end
  end

  def log_success(investment, profit_record)
    Rails.logger.info(
      "[GenerateDailyProfitsJob] Profit generated — " \
        "investment_id=#{investment.id} " \
        "profit_date=#{profit_record.profit_date} " \
        "amount=#{profit_record.amount}"
    )
  end

  def log_skip_or_failure(investment, error_message)
    Rails.logger.warn(
      "[GenerateDailyProfitsJob] Profit skipped — " \
        "investment_id=#{investment.id} " \
        "reason=#{error_message}"
    )
  end

  def log_unexpected_failure(investment, error)
    Rails.logger.error(
      "[GenerateDailyProfitsJob] Unexpected failure — " \
        "investment_id=#{investment.id} " \
        "error=#{error.class}: #{error.message}"
    )
  end
end