class InvestmentPlanPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active.ordered
    end
  end
end