require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  # Default role
  test "new user has member role by default" do
    user = User.new(
      full_name:             "Role Test User",
      email:                 "roletest@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    assert user.member?
    assert_equal "member", user.role
  end

  test "user created via create_confirmed_user helper has member role" do
    user = create_confirmed_user
    assert user.member?
    assert_not user.admin?
  end

  # Member role
  test "user can be assigned member role explicitly" do
    user = create_confirmed_user
    user.update!(role: :member)
    assert user.member?
    assert_equal "member", user.role
  end

  test "member? returns true for member users" do
    user = create_confirmed_user
    assert user.member?
  end

  test "admin? returns false for member users" do
    user = create_confirmed_user
    assert_not user.admin?
  end

  # Admin role
  test "user can be assigned admin role" do
    user = create_confirmed_user
    user.update!(role: :admin)
    assert user.admin?
    assert_equal "admin", user.role
  end

  test "admin? returns true for admin users" do
    user = create_confirmed_user
    user.update!(role: :admin)
    assert user.admin?
  end

  test "member? returns false for admin users" do
    user = create_confirmed_user
    user.update!(role: :admin)
    assert_not user.member?
  end

  # Role validation
  test "user is invalid without a role" do
    user = create_confirmed_user
    user.role = nil
    assert_not user.valid?
    assert user.errors[:role].any?
  end

  # Role scopes
  test "User.member scope returns only member users" do
    member = create_confirmed_user
    admin  = create_confirmed_user
    admin.update!(role: :admin)
    assert_includes     User.member, member
    assert_not_includes User.member, admin
  end

  test "User.admin scope returns only admin users" do
    member = create_confirmed_user
    admin  = create_confirmed_user
    admin.update!(role: :admin)
    assert_includes     User.admin, admin
    assert_not_includes User.admin, member
  end
end