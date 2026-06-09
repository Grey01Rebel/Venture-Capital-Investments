require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Valid user creation
  test "creates a valid user with all required attributes" do
    user = User.new(
      full_name: "Jane Investor",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?, "Expected user to be valid but got: #{user.errors.full_messages}"
  end

  # full_name presence validation
  test "is invalid without a full_name" do
    user = User.new(
      full_name: "",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:full_name], "can't be blank"
  end

  # full_name maximum length validation
  test "is invalid when full_name exceeds 100 characters" do
    user = User.new(
      full_name: "A" * 101,
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:full_name], "is too long (maximum is 100 characters)"
  end

  test "is valid when full_name is exactly 100 characters" do
    user = User.new(
      full_name: "A" * 100,
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?, "Expected user with 100 char name to be valid"
  end

  # email validations
  test "is invalid without an email" do
    user = User.new(
      full_name: "Jane Investor",
      email: "",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "is invalid with a duplicate email" do
    create_confirmed_user(email: "duplicate@example.com")
    user = User.new(
      full_name: "Another User",
      email: "duplicate@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  # password validations
  test "is invalid when password is fewer than 8 characters" do
    user = User.new(
      full_name: "Jane Investor",
      email: "jane@example.com",
      password: "short",
      password_confirmation: "short"
    )
    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "is invalid when password confirmation does not match" do
    user = User.new(
      full_name: "Jane Investor",
      email: "jane@example.com",
      password: "password123",
      password_confirmation: "different123"
    )
    assert_not user.valid?
    assert user.errors[:password_confirmation].any?
  end

  # has_one wallet association
  test "has one wallet association" do
    user = create_confirmed_user
    assert_respond_to user, :wallet
    assert_instance_of Wallet, user.wallet
  end

  # automatic wallet creation after user creation
  test "automatically creates a wallet after user is created" do
    user = User.create!(
      full_name: "New Investor",
      email: "newinvestor@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_not_nil user.wallet
    assert_instance_of Wallet, user.wallet
  end

  test "wallet is persisted to the database after user creation" do
    assert_difference "Wallet.count", 1 do
      User.create!(
        full_name: "New Investor",
        email: "wallet_persist@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end
  end

  test "destroying a user also destroys their wallet" do
    user = create_confirmed_user
    wallet_id = user.wallet.id
    user.destroy
    assert_nil Wallet.find_by(id: wallet_id)
  end
end