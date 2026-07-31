class Agents::MarkOfflineService
  pattr_initialize [:user!]

  def perform
    user.account_users.includes(:account).find_each do |account_user|
      account_user.update!(availability: :offline)
      OnlineStatusTracker.mark_user_offline(account_user.account.id, user.id)
    end
  end
end
