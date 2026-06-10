ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Parallelisation disabled — shared PostgreSQL state causes
    # unique constraint collisions across workers with fixture-free tests.
    # Re-enable when a proper factory strategy is introduced.
    parallelize(workers: 1)

    fixtures :all

    def create_confirmed_user(attrs = {})
      user = User.create!({
                            full_name: "Test User",
                            email: "test_#{SecureRandom.hex(4)}@example.com",
                            password: "password123",
                            password_confirmation: "password123"
                          }.merge(attrs))
      user.confirm
      user
    end

    def create_investment_plan(attrs = {})
      defaults = {
        name: "Test Plan #{SecureRandom.hex(6)}",
        description: "A test plan.",
        investment_amount_usd: 1_000.00,
        daily_return_rate: 1.00,
        duration_days: 14,
        active: true,
        position: rand(1_000..9_999)
      }
      InvestmentPlan.create!(defaults.merge(attrs))
    end

    def create_all_six_plans
      # Use unique suffixes on position to avoid collisions if called
      # multiple times in the same test run.
      offset = InvestmentPlan.maximum(:position).to_i
      offset = [offset, 0].max

      [
        { position: offset + 1, name: "Starter",  investment_amount_usd: 500.00,  daily_return_rate: 0.80 },
        { position: offset + 2, name: "Bronze",   investment_amount_usd: 1_000.00, daily_return_rate: 0.90 },
        { position: offset + 3, name: "Silver",   investment_amount_usd: 2_000.00, daily_return_rate: 1.00 },
        { position: offset + 4, name: "Gold",     investment_amount_usd: 3_000.00, daily_return_rate: 1.20 },
        { position: offset + 5, name: "Platinum", investment_amount_usd: 4_000.00, daily_return_rate: 1.35 },
        { position: offset + 6, name: "VIP",      investment_amount_usd: 5_000.00, daily_return_rate: 1.50 }
      ].map do |attrs|
        InvestmentPlan.create!(
          attrs.merge(
            description: "Test description for #{attrs[:name]}.",
            duration_days: 14,
            active: true
          )
        )
      end
    end
  end
end