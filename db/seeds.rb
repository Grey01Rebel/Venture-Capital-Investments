# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


# db/seeds.rb

plans = [
  {
    position: 1,
    name: "Starter",
    investment_amount_usd: 500.00,
    daily_return_rate: 0.80,
    duration_days: 14,
    active: true,
    description: "An entry-level position in our Bitcoin mining operations. " \
      "Allocated to stable, established mining pools with consistent " \
      "block reward distribution. Designed for investors seeking " \
      "measured exposure to digital asset infrastructure with " \
      "predictable return cadence over a 14-day cycle."
  },
  {
    position: 2,
    name: "Bronze",
    investment_amount_usd: 1_000.00,
    daily_return_rate: 0.90,
    duration_days: 14,
    active: true,
    description: "A foundational allocation providing access to diversified " \
      "Bitcoin mining capacity across multiple facilities. This plan " \
      "balances operational efficiency with incremental yield, " \
      "suitable for investors building a disciplined position in " \
      "proof-of-work asset generation over a structured 14-day term."
  },
  {
    position: 3,
    name: "Silver",
    investment_amount_usd: 2_000.00,
    daily_return_rate: 1.00,
    duration_days: 14,
    active: true,
    description: "A mid-tier allocation offering full participation in our " \
      "institutional mining infrastructure. Capital is deployed " \
      "across high-efficiency ASIC operations, prioritising uptime " \
      "and hash rate stability. Appropriate for investors with a " \
      "medium-term outlook on Bitcoin network fundamentals."
  },
  {
    position: 4,
    name: "Gold",
    investment_amount_usd: 3_000.00,
    daily_return_rate: 1.20,
    duration_days: 14,
    active: true,
    description: "A premium allocation with preferential access to high-output " \
      "mining operations. Positions in this tier benefit from " \
      "optimised energy procurement and next-generation hardware " \
      "deployment. Structured for serious investors seeking " \
      "meaningful exposure to Bitcoin production at institutional scale."
  },
  {
    position: 5,
    name: "Platinum",
    investment_amount_usd: 4_000.00,
    daily_return_rate: 1.35,
    duration_days: 14,
    active: true,
    description: "An advanced allocation reserved for committed participants " \
      "in our core mining operations. Capital at this tier is " \
      "deployed into flagship facilities with the highest operational " \
      "efficiency ratios. Designed for investors who understand " \
      "Bitcoin mining economics and seek proportionate returns."
  },
  {
    position: 6,
    name: "VIP",
    investment_amount_usd: 5_000.00,
    daily_return_rate: 1.50,
    duration_days: 14,
    active: true,
    description: "The highest-tier allocation, granting priority access to our " \
      "most productive mining capacity. VIP positions are supported " \
      "by dedicated infrastructure, institutional-grade security, " \
      "and direct operational oversight. Reserved for discerning " \
      "investors requiring the highest standard of asset management."
  }
]

plans.each do |attrs|
  plan = InvestmentPlan.find_or_create_by(name: attrs[:name]) do |p|
    p.assign_attributes(attrs)
  end
  puts "#{plan.persisted? ? 'Seeded' : 'Failed'}: #{plan.name}"
end