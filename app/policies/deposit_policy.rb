class DepositPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    admin_or_owner?
  end

  def new?
    true
  end

  def create?
    true
  end

  def approve?
    user.admin?
  end

  def reject?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  private

  def admin_or_owner?
    user.admin? || record.user_id == user.id
  end
end