require "test_helper"

class DepositsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user       = create_confirmed_user
    @other_user = create_confirmed_user
    @plan       = create_investment_plan(position: 601)
    @deposit    = Deposit.create!(
      user:             @user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00812345,
      transaction_hash: "ctrl#{SecureRandom.hex(30)}",
      submitted_at:     Time.current
    )
  end

  # --- index ---

  test "authenticated user can access deposits index" do
    sign_in @user
    get deposits_path
    assert_response :success
  end

  test "unauthenticated user is redirected from deposits index" do
    get deposits_path
    assert_redirected_to new_user_session_path
  end

  test "deposits index only shows current user deposits" do
    other_deposit = Deposit.create!(
      user:             @other_user,
      investment_plan:  @plan,
      amount_usd:       @plan.investment_amount_usd,
      btc_amount:       0.00500000,
      transaction_hash: "other#{SecureRandom.hex(29)}",
      submitted_at:     Time.current
    )
    sign_in @user
    get deposits_path
    assert_match @plan.name, response.body
    assert_no_match other_deposit.transaction_hash, response.body
  end

  # --- show ---

  test "authenticated user can view their own deposit" do
    sign_in @user
    get deposit_path(@deposit)
    assert_response :success
  end

  test "unauthenticated user is redirected from deposit show" do
    get deposit_path(@deposit)
    assert_redirected_to new_user_session_path
  end

  test "user cannot view another user's deposit" do
    sign_in @other_user
    get deposit_path(@deposit)
    assert_response :redirect
  end

  # --- new ---

  test "authenticated user can access new deposit form with valid plan" do
    sign_in @user
    get new_deposit_path(investment_plan_id: @plan.id)
    assert_response :success
  end

  test "unauthenticated user is redirected from new deposit form" do
    get new_deposit_path(investment_plan_id: @plan.id)
    assert_redirected_to new_user_session_path
  end

  test "new deposit form redirects to plans if plan id is missing" do
    sign_in @user
    get new_deposit_path
    assert_redirected_to plans_path
  end

  test "new deposit form redirects to plans if plan id is invalid" do
    sign_in @user
    get new_deposit_path(investment_plan_id: 999999)
    assert_redirected_to plans_path
  end

  test "new deposit form redirects to plans if plan is inactive" do
    inactive_plan = create_investment_plan(active: false, position: 602)
    sign_in @user
    get new_deposit_path(investment_plan_id: inactive_plan.id)
    assert_redirected_to plans_path
  end

  test "new deposit form displays plan name" do
    sign_in @user
    get new_deposit_path(investment_plan_id: @plan.id)
    assert_match @plan.name, response.body
  end

  # --- create ---

  test "authenticated user can create a deposit" do
    sign_in @user
    assert_difference "Deposit.count", 1 do
      post deposits_path(investment_plan_id: @plan.id), params: {
        deposit: {
          btc_amount:       "0.00900000",
          transaction_hash: "new#{SecureRandom.hex(30)}"
        }
      }
    end
    assert_redirected_to deposit_path(Deposit.last)
  end

  test "unauthenticated user cannot create a deposit" do
    assert_no_difference "Deposit.count" do
      post deposits_path(investment_plan_id: @plan.id), params: {
        deposit: {
          btc_amount:       "0.00900000",
          transaction_hash: "unauth#{SecureRandom.hex(28)}"
        }
      }
    end
    assert_redirected_to new_user_session_path
  end

  test "deposit is created with amount_usd copied from plan" do
    sign_in @user
    post deposits_path(investment_plan_id: @plan.id), params: {
      deposit: {
        btc_amount:       "0.00900000",
        transaction_hash: "amount#{SecureRandom.hex(28)}"
      }
    }
    assert_equal @plan.investment_amount_usd, Deposit.last.amount_usd
  end

  test "deposit is created with pending status" do
    sign_in @user
    post deposits_path(investment_plan_id: @plan.id), params: {
      deposit: {
        btc_amount:       "0.00900000",
        transaction_hash: "status#{SecureRandom.hex(28)}"
      }
    }
    assert Deposit.last.pending?
  end

  test "deposit is created with submitted_at set" do
    sign_in @user
    post deposits_path(investment_plan_id: @plan.id), params: {
      deposit: {
        btc_amount:       "0.00900000",
        transaction_hash: "subat#{SecureRandom.hex(29)}"
      }
    }
    assert_not_nil Deposit.last.submitted_at
  end

  test "user cannot inject amount_usd via form params" do
    sign_in @user
    post deposits_path(investment_plan_id: @plan.id), params: {
      deposit: {
        btc_amount:       "0.00900000",
        transaction_hash: "inject#{SecureRandom.hex(28)}",
        amount_usd:       "0.01"
      }
    }
    assert_equal @plan.investment_amount_usd, Deposit.last.amount_usd
  end

  test "user cannot inject status via form params" do
    sign_in @user
    post deposits_path(investment_plan_id: @plan.id), params: {
      deposit: {
        btc_amount:       "0.00900000",
        transaction_hash: "injst#{SecureRandom.hex(28)}",
        status:           "approved"
      }
    }
    assert Deposit.last.pending?
  end

  test "create fails with duplicate transaction hash" do
    sign_in @user
    assert_no_difference "Deposit.count" do
      post deposits_path(investment_plan_id: @plan.id), params: {
        deposit: {
          btc_amount:       "0.00900000",
          transaction_hash: @deposit.transaction_hash
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create fails without btc_amount" do
    sign_in @user
    assert_no_difference "Deposit.count" do
      post deposits_path(investment_plan_id: @plan.id), params: {
        deposit: {
          btc_amount:       "",
          transaction_hash: "nobta#{SecureRandom.hex(28)}"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create fails without transaction_hash" do
    sign_in @user
    assert_no_difference "Deposit.count" do
      post deposits_path(investment_plan_id: @plan.id), params: {
        deposit: {
          btc_amount:       "0.00900000",
          transaction_hash: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end
end