require "test_helper"

class WalletTest < ActiveSupport::TestCase
  def setup
    @user = create_confirmed_user
    @wallet = @user.wallet
  end

  # belongs_to user association
  test "belongs to a user" do
    assert_respond_to @wallet, :user
    assert_equal @user, @wallet.user
  end

  test "is invalid without a user" do
    wallet = Wallet.new
    assert_not wallet.valid?
    assert_includes wallet.errors[:user], "must exist"
  end

  # uniqueness of user
  test "enforces one wallet per user" do
    duplicate_wallet = Wallet.new(user: @user)
    assert_not duplicate_wallet.valid?
    assert_includes duplicate_wallet.errors[:user], "has already been taken"
  end

  # all monetary fields default to 0
  test "available_balance defaults to zero" do
    assert_equal 0, @wallet.available_balance
  end

  test "total_deposited defaults to zero" do
    assert_equal 0, @wallet.total_deposited
  end

  test "total_withdrawn defaults to zero" do
    assert_equal 0, @wallet.total_withdrawn
  end

  test "total_profit defaults to zero" do
    assert_equal 0, @wallet.total_profit
  end

  test "all monetary fields are zero on a freshly created wallet" do
    Wallet::MONETARY_FIELDS.each do |field|
      assert_equal 0, @wallet.public_send(field),
                   "Expected #{field} to default to 0"
    end
  end

  # negative values are rejected
  test "rejects negative available_balance" do
    @wallet.available_balance = -1
    assert_not @wallet.valid?
    assert @wallet.errors[:available_balance].any?
  end

  test "rejects negative total_deposited" do
    @wallet.total_deposited = -0.00000001
    assert_not @wallet.valid?
    assert @wallet.errors[:total_deposited].any?
  end

  test "rejects negative total_withdrawn" do
    @wallet.total_withdrawn = -100
    assert_not @wallet.valid?
    assert @wallet.errors[:total_withdrawn].any?
  end

  test "rejects negative total_profit" do
    @wallet.total_profit = -50
    assert_not @wallet.valid?
    assert @wallet.errors[:total_profit].any?
  end

  test "accepts zero for all monetary fields" do
    Wallet::MONETARY_FIELDS.each do |field|
      @wallet.public_send(:"#{field}=", 0)
      assert @wallet.valid?, "Expected #{field} = 0 to be valid"
    end
  end

  test "accepts positive values for all monetary fields" do
    Wallet::MONETARY_FIELDS.each do |field|
      @wallet.public_send(:"#{field}=", 100.00)
      assert @wallet.valid?, "Expected #{field} = 100.00 to be valid"
    end
  end

  # decimal precision
  test "stores monetary values with high decimal precision" do
    @wallet.available_balance = BigDecimal("12345678.12345678")
    @wallet.save!
    @wallet.reload
    assert_equal BigDecimal("12345678.12345678"), @wallet.available_balance
  end
end