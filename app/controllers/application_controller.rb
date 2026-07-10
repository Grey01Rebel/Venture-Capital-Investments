class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Rails' `config.permissions_policy` only emits the legacy, now
  # browser-unsupported `Feature-Policy` header rather than the modern
  # `Permissions-Policy` header — see rails/rails#48878. The application
  # has no legitimate use for any of these browser features, so the real
  # header is set explicitly here instead. See docs/Decisions.md, ADR-019.
  PERMISSIONS_POLICY = "camera=(), microphone=(), geolocation=(), usb=(), payment=(), fullscreen=()"

  after_action :set_permissions_policy_header

  private

  def user_not_authorized
    redirect_to authenticated_root_path, alert: "You are not authorised to perform that action."
  end

  def set_permissions_policy_header
    response.headers["Permissions-Policy"] = PERMISSIONS_POLICY
  end
end