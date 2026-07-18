class Api::V1::Profile::SessionsController < Api::BaseController
  before_action :set_session, only: [:destroy]

  def index
    @sessions = current_user.user_sessions.where(client_id: session_revocation.active_token_client_ids)
                            .order(last_activity_at: :desc)
    @current_client_id = request.headers['client']
  end

  def destroy
    if @session.current?(request.headers['client'])
      render json: { error: I18n.t('profile_settings.sessions.cannot_revoke_current') }, status: :unprocessable_entity
      return
    end

    session_revocation.revoke_token!(@session.client_id)
    @session.destroy!
    head :ok
  end

  private

  def set_session
    @session = current_user.user_sessions.find(params[:id])
  end

  def session_revocation
    @session_revocation ||= UserSessionRevocationService.new(current_user)
  end
end
