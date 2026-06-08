class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable

  has_one :wallet, dependent: :destroy

  validates :full_name, presence: true, length: { maximum: 100 }

  after_commit :create_wallet!, on: :create

  private

  def create_wallet!
    Wallet.create!(user: self)
  end
end