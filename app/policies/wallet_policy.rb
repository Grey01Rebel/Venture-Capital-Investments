class WalletPolicy < ApplicationPolicy
  def show?
    record.present? && record.user_id == user.id
  end
end