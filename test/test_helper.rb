ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    # Builds a valid confirmed user for use across tests
    def create_confirmed_user(attrs = {})
      user = User.create!({
                            full_name: "Test User",
                            email: "test_#{SecureRandom.hex(4)}@example.com",
                            password: "password123",
                            password_confirmation: "password123"
                          }.merge(attrs))
      user.confirm
      user
    end
  end
end