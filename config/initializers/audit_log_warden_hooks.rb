# frozen_string_literal: true

# Devise authenticates entirely through Warden, so successful sign-in,
# sign-out, and failed sign-in attempts are not controller actions this
# application owns — there is no custom SessionsController to hook into.
# These Warden callbacks are the equivalent call site for that layer, as
# referenced in AuditLog's own documentation ("services, controllers, the
# Warden failure hook"). See docs/Decisions.md, ADR-020.

Warden::Manager.after_authentication do |user, auth, opts|
  next unless opts[:scope] == :user

  request = ActionDispatch::Request.new(auth.env)
  AuditLog.record!(
    action:     "user.signed_in",
    actor:      user,
    ip_address: request.remote_ip
  )
end

Warden::Manager.before_logout do |user, auth, opts|
  next unless opts[:scope] == :user

  request = ActionDispatch::Request.new(auth.env)
  AuditLog.record!(
    action:     "user.signed_out",
    actor:      user,
    ip_address: request.remote_ip
  )
end

Warden::Manager.before_failure do |env, opts|
  next unless opts[:scope] == :user
  # Warden defaults opts[:action] to :unauthenticated on *every* auth
  # failure, including real failed login attempts — it can't be used to
  # tell those apart from a bare anonymous visit to a protected page.
  # opts[:message] is the actual signal: Devise's strategy sets it to a
  # specific reason (:invalid, :unconfirmed, :locked, etc.) only when
  # credentials were actually submitted and rejected. For a plain
  # unauthenticated page visit, no strategy runs at all, so it stays nil.
  next if opts[:message].blank?

  request = ActionDispatch::Request.new(env)
  AuditLog.record!(
    action:     "user.sign_in_failed",
    ip_address: request.remote_ip,
    metadata:   {
      reason:          opts[:message].to_s,
      attempted_email: request.params.dig("user", "email")
    }.compact
  )
end
