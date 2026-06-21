class CompleteInvestmentsJob < ApplicationJob
  queue_as :default

  def perform
    Investment.active.find_each do |investment|
      process_investment(investment)
    rescue StandardError => e
      log_unexpected_failure(investment, e)
    end
  end

  private

  def process_investment(investment)
    result = CompleteInvestmentService.new(investment).call

    if result.success?
      log_success(investment)
    else
      log_skip_or_failure(investment, result.error)
    end
  end

  def log_success(investment)
    Rails.logger.info(
      "[CompleteInvestmentsJob] Completed investment #{investment.id}"
    )
  end

  def log_skip_or_failure(investment, error_message)
    Rails.logger.warn(
      "[CompleteInvestmentsJob] Skipped investment #{investment.id}: #{error_message}"
    )
  end

  def log_unexpected_failure(investment, error)
    Rails.logger.error(
      "[CompleteInvestmentsJob] Error completing investment #{investment.id}: #{error.class}: #{error.message}"
    )
  end
end