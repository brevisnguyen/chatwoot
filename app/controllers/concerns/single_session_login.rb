module SingleSessionLogin
  extend ActiveSupport::Concern

  private

  def track_user_session
    client_id = login_client_id
    return unless client_id.present? && @resource.present?

    UserSessionTrackingService.new(
      user: @resource,
      request: request,
      client_id: client_id
    ).create_or_update!
  rescue StandardError => e
    Rails.logger.warn "Session tracking failed: #{e.message}"
  end

  def enforce_single_session!
    client_id = login_client_id
    return if client_id.blank? || @resource.blank?

    UserSessionRevocationService.new(@resource).revoke_other_sessions_and_notify!(except_client_id: client_id)
  end

  def login_client_id
    @token&.try(:client) || response.headers['client']
  end
end
