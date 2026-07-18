class UserSessionRevocationService
  def initialize(user)
    @user = user
  end

  def active_token_client_ids
    now = Time.current.to_i
    (@user.tokens || {}).select { |_, v| v['expiry'].to_i > now }.keys
  end

  def revoke_token!(client_id)
    tokens = @user.tokens
    tokens.delete(client_id)
    @user.update!(tokens: tokens)
  end

  # Revokes every session/token except +except_client_id+. Returns revoked client_ids.
  def revoke_other_sessions!(except_client_id:)
    return [] if except_client_id.blank?

    revoked = revoke_tracked_sessions!(except_client_id)
    revoked.concat(revoke_orphan_tokens!(except_client_id))
    revoked.uniq
  end

  # pubsub_token is shared across devices — payload includes client_ids for frontend filtering.
  def revoke_other_sessions_and_notify!(except_client_id:)
    revoked_ids = revoke_other_sessions!(except_client_id: except_client_id)
    return revoked_ids if revoked_ids.blank?

    ActionCableBroadcastJob.perform_later(
      [@user.pubsub_token],
      'user:logout',
      { reason: 'session_replaced', client_ids: revoked_ids }
    )
    revoked_ids
  end

  private

  def revoke_tracked_sessions!(except_client_id)
    revoked = []
    @user.user_sessions.where(client_id: active_token_client_ids).find_each do |session|
      next if session.current?(except_client_id)

      revoke_token!(session.client_id)
      revoked << session.client_id
      session.destroy!
    end
    revoked
  end

  # Tokens without a UserSession row (legacy / race) — drop all except the current client.
  def revoke_orphan_tokens!(except_client_id)
    orphan_ids = (@user.reload.tokens || {}).keys - [except_client_id]
    orphan_ids.each { |client_id| revoke_token!(client_id) }
    orphan_ids
  end
end
