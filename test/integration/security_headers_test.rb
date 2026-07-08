# frozen_string_literal: true
require "test_helper"

class SecurityHeadersTest < ActionDispatch::IntegrationTest
  test "sets a Content-Security-Policy header" do
    get root_path # unauthenticated root is the sign-in page
    assert_response :success

    csp = response.headers["Content-Security-Policy"]
    assert_not_nil csp

    assert_match "default-src 'self'", csp
    assert_match "object-src 'none'", csp
    assert_match "frame-ancestors 'none'", csp
    assert_match "base-uri 'self'", csp
    assert_match "form-action 'self'", csp
  end

  test "script-src does not allow unsafe-inline" do
    get root_path
    csp = response.headers["Content-Security-Policy"]

    script_src_directive = csp.split(";").find { |d| d.strip.start_with?("script-src") }
    assert_not_nil script_src_directive
    assert_no_match "unsafe-inline", script_src_directive
  end

  test "script-src carries a per-session nonce" do
    get root_path
    csp = response.headers["Content-Security-Policy"]

    assert_match(/script-src[^;]*'nonce-/, csp)
  end

  test "sets a Permissions-Policy header restricting unused browser features" do
    get root_path
    assert_response :success

    policy = response.headers["Permissions-Policy"]
    assert_not_nil policy

    assert_match "camera=()", policy
    assert_match "microphone=()", policy
    assert_match "geolocation=()", policy
    assert_match "payment=()", policy
  end

  test "Rails' framework-default secure headers remain active" do
    get root_path

    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end
end
