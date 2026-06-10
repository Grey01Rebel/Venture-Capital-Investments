require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  include Warden::Test::Helpers
  Warden.test_mode!

  teardown do
    Warden.test_reset!
  end
end