module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    private

    def require_admin!
      unless current_user.admin?
        redirect_to authenticated_root_path,
                    alert: "You are not authorized to access the admin area."
      end
    end
  end
end