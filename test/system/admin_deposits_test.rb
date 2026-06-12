require "application_system_test_case"

class AdminDepositsTest < ApplicationSystemTestCase
  def setup
    @admin = User.create!(
      full_name:             "Admin User",
      email:                 "admin@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @admin.confirm
    @admin.update!(role: :admin)

    @member = User.create!(
      full_name:             "Member User",
      email:                 "member@example.com",
      password:              "password123",
      password_confirmation: "password123"
    )
    @member.confirm

    create_all_six_plans
    @plan = InvestmentPlan.find_by(name: "Starter")

    @deposit = Deposit.create!(
      user:             @member,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "adm#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
  end

  # Admin can access the deposit review index
  test "admin can visit the deposit review index" do
    login_as @admin
    visit admin_deposits_path
    assert_current_path admin_deposits_path
    assert_text "Deposit Review"
  end

  # Pending deposits appear on the index
  test "pending deposit appears on admin index" do
    login_as @admin
    visit admin_deposits_path
    assert_text @member.full_name
    assert_text "Starter"
    assert_text "$500.00"
    assert_text "Pending"
  end

  # Admin can view deposit show page
  test "admin can view deposit show page" do
    login_as @admin
    visit admin_deposit_path(@deposit)
    assert_text "Deposit ##{@deposit.id}"
    assert_text @member.full_name
    assert_text @deposit.transaction_hash
    assert_text "Approve Deposit"
    assert_text "Reject Deposit"
  end

  # Admin can approve a deposit
  test "admin can approve a pending deposit" do
    login_as @admin
    visit admin_deposit_path(@deposit)
    click_button "Approve Deposit"
    assert_text "Deposit approved successfully"
    assert_text "Approved"
    assert_no_text "Approve Deposit"
    assert_no_text "Reject Deposit"
  end

  # Admin can approve with notes
  test "admin can approve a deposit with notes" do
    login_as @admin
    visit admin_deposit_path(@deposit)
    within("form[action='#{approve_admin_deposit_path(@deposit)}']") do
      fill_in "admin_notes", with: "Verified on blockchain explorer."
      click_button "Approve Deposit"
    end
    assert_text "Deposit approved successfully"
    assert_text "Verified on blockchain explorer."
  end

  # Admin can reject a deposit
  test "admin can reject a pending deposit" do
    login_as @admin
    visit admin_deposit_path(@deposit)
    click_button "Reject Deposit"
    assert_text "Deposit rejected successfully"
    assert_text "Rejected"
    assert_no_text "Approve Deposit"
    assert_no_text "Reject Deposit"
  end

  # Admin can reject with notes
  test "admin can reject a deposit with notes" do
    login_as @admin
    visit admin_deposit_path(@deposit)
    within("form[action='#{reject_admin_deposit_path(@deposit)}']") do
      fill_in "admin_notes", with: "Transaction hash not found on chain."
      click_button "Reject Deposit"
    end
    assert_text "Deposit rejected successfully"
    assert_text "Transaction hash not found on chain."
  end
  # Reviewed deposit shows read-only review record
  test "approved deposit shows read-only review record" do
    @deposit.approve!(reviewer: @admin, notes: "Confirmed.")
    login_as @admin
    visit admin_deposit_path(@deposit)
    assert_text "Review Record"
    assert_text "Admin User"
    assert_text "Confirmed."
    assert_no_text "Approve Deposit"
    assert_no_text "Reject Deposit"
  end

  # Cannot re-review an already reviewed deposit
  test "already approved deposit cannot be approved again" do
    @deposit.approve!(reviewer: @admin)
    login_as @admin
    visit admin_deposit_path(@deposit)
    assert_no_text "Approve Deposit"
    assert_no_text "Reject Deposit"
    assert_text "Review Record"
  end

  # Member cannot access admin area
  test "member is redirected from admin deposit index" do
    login_as @member
    visit admin_deposits_path
    assert_current_path authenticated_root_path
  end

  test "member is redirected from admin deposit show" do
    login_as @member
    visit admin_deposit_path(@deposit)
    assert_current_path authenticated_root_path
  end

  # Status filter tabs work
  test "approved tab shows approved deposits" do
    @deposit.approve!(reviewer: @admin)
    login_as @admin
    visit admin_deposits_path(status: "approved")
    assert_text "Approved"
    assert_text @member.full_name
  end

  test "rejected tab shows rejected deposits" do
    @deposit.reject!(reviewer: @admin)
    login_as @admin
    visit admin_deposits_path(status: "rejected")
    assert_text "Rejected"
    assert_text @member.full_name
  end

  # Admin nav link visible to admins
  test "admin nav link is visible to admin users" do
    login_as @admin
    visit authenticated_root_path
    assert_selector "a[href='#{admin_deposits_path}']"
  end

  # Admin nav link not visible to members
  test "admin nav link is not visible to member users" do
    login_as @member
    visit authenticated_root_path
    assert_no_selector "a[href='#{admin_deposits_path}']"
  end
end