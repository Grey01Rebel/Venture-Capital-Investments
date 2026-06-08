class WalletPolicy < ApplicationPolicy
  def show?
    record.user_id == user.id
  end
end