# Be sure to restart your server when you modify this file.

# Application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
#
# This app serves no external resources — no third-party fonts, CDNs, or
# embedded content — so the policy is scoped to :self rather than the
# broader :https allowance in Rails' generated template.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src  :self
    policy.font_src     :self, :data
    policy.img_src      :self, :data
    policy.object_src   :none
    policy.script_src   :self
    # unsafe_inline is required for style-src only: the investment
    # performance view sets an inline `style="width: X%"` attribute for a
    # progress bar. CSP nonces cover <script>/<style> elements, not raw
    # inline style="" attributes on arbitrary tags, so this can't be
    # closed with a nonce alone. See docs/Decisions.md, ADR-018.
    policy.style_src    :self, :unsafe_inline
    policy.base_uri     :self
    policy.form_action  :self
    policy.frame_ancestors :none
  end

  # Generate session nonces for importmap and inline <script> tags.
  # style-src is intentionally excluded — see the comment above.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
