require "test_helper"

class Admin::DepositsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin = create_confirmed_user
    @admin.update!(role: :admin)

    @member = create_confirmed_user

    @plan = create_investment_plan(position: 801)

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "admc#{SecureRandom.hex(29)}",
      submitted_at:     Time.current
    )
  end

  # --- index ---

  test "admin can access deposit review index" do
    sign_in @admin
    get admin_deposits_path
    assert_response :success
  end

  test "member cannot access admin deposit index" do
    sign_in @member
    get admin_deposits_path
    assert_redirected_to authenticated_root_path
  end

  test "unauthenticated user cannot access admin deposit index" do
    get admin_deposits_path
    assert_redirected_to new_user_session_path
  end

  test "index defaults to pending status filter" do
    sign_in @admin
    get admin_deposits_path
    assert_match "Pending", response.body
  end

  test "index filters by approved status" do
    @deposit.approve!(reviewer: @admin)
    sign_in @admin
    get admin_deposits_path(status: "approved")
    assert_response :success
    assert_match "Approved", response.body
  end

  test "index filters by rejected status" do
    @deposit.reject!(reviewer: @admin)
    sign_in @admin
    get admin_deposits_path(status: "rejected")
    assert_response :success
    assert_match "Rejected", response.body
  end

  # --- show ---

  test "admin can view any deposit" do
    sign_in @admin
    get admin_deposit_path(@deposit)
    assert_response :success
  end

  test "member cannot access admin deposit show" do
    sign_in @member
    get admin_deposit_path(@deposit)
    assert_redirected_to authenticated_root_path
  end

  # --- approve ---

  test "admin can approve a pending deposit" do
    sign_in @admin
    patch approve_admin_deposit_path(@deposit)
    @deposit.reload
    assert @deposit.approved?
    assert_redirected_to admin_deposit_path(@deposit)
  end

  test "approve sets reviewed_by to current admin" do
    sign_in @admin
    patch approve_admin_deposit_path(@deposit)
    @deposit.reload
    assert_equal @admin, @deposit.reviewer
  end

  test "approve sets approved_at" do
    sign_in @admin
    patch approve_admin_deposit_path(@deposit)
    @deposit.reload
    assert_not_nil @deposit.approved_at
  end

  test "approve records admin_notes when provided" do
    sign_in @admin
    patch approve_admin_deposit_path(@deposit), params: { admin_notes: "Verified." }
    @deposit.reload
    assert_equal "Verified.", @deposit.admin_notes
  end

  test "approving already approved deposit redirects with alert" do
    @deposit.approve!(reviewer: @admin)
    sign_in @admin
    patch approve_admin_deposit_path(@deposit)
    assert_redirected_to admin_deposit_path(@deposit)
    assert_equal "This deposit has already been reviewed and cannot be approved.",
                 flash[:alert]
  end

  test "member cannot approve a deposit" do
    sign_in @member
    patch approve_admin_deposit_path(@deposit)
    assert_redirected_to authenticated_root_path
    @deposit.reload
    assert @deposit.pending?
  end

  # --- reject ---

  test "admin can reject a pending deposit" do
    sign_in @admin
    patch reject_admin_deposit_path(@deposit)
    @deposit.reload
    assert @deposit.rejected?
    assert_redirected_to admin_deposit_path(@deposit)
  end

  test "reject sets reviewed_by to current admin" do
    sign_in @admin
    patch reject_admin_deposit_path(@deposit)
    @deposit.reload
    assert_equal @admin, @deposit.reviewer
  end

  test "reject sets rejected_at" do
    sign_in @admin
    patch reject_admin_deposit_path(@deposit)
    @deposit.reload
    assert_not_nil @deposit.rejected_at
  end

  test "reject records admin_notes when provided" do
    sign_in @admin
    patch reject_admin_deposit_path(@deposit), params: { admin_notes: "Hash not found." }
    @deposit.reload
    assert_equal "Hash not found.", @deposit.admin_notes
  end

  test "rejecting already rejected deposit redirects with alert" do
    @deposit.reject!(reviewer: @admin)
    sign_in @admin
    patch reject_admin_deposit_path(@deposit)
    assert_redirected_to admin_deposit_path(@deposit)
    assert_equal "This deposit has already been reviewed and cannot be rejected.",
                 flash[:alert]
  end

  test "member cannot reject a deposit" do
    sign_in @member
    patch reject_admin_deposit_path(@deposit)
    assert_redirected_to authenticated_root_path
    @deposit.reload
    assert @deposit.pending?
  end
end