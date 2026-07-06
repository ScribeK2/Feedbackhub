ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "turbo/broadcastable/test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # turbo-rails only mixes this in once Action Cable happens to load, which is
    # seed-dependent under parallel workers — include it deterministically.
    include Turbo::Broadcastable::TestHelper
  end
end

module AuthenticationHelper
  def sign_in(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  def sign_in_as_admin
    sign_in(users(:admin))
  end

  def sign_in_as_user
    sign_in(users(:regular))
  end

  def sign_in_as_manager
    sign_in(users(:manager))
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelper
end
