module AutoAssignmentHandler
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_save :run_auto_assignment
  end

  private

  def run_auto_assignment
    # Assignment V2: Also trigger assignment when conversation is resolved or snoozed,
    # bypassing the open-only condition so the AssignmentJob can redistribute capacity.
    return unless conversation_status_changed_to_open? || conversation_status_changed_to_resolved_or_snoozed?
    return unless should_run_auto_assignment?

    if inbox.auto_assignment_v2_enabled?
      # Coalesces bursts of triggers per inbox. Fine if the job runs even when the
      # surrounding save rolls back: it only scans the inbox's current unassigned
      # conversations, so running it for an uncommitted change is harmless.
      clear_offline_assignee_for_v2!
      AutoAssignment::AssignmentJob.enqueue_for_inbox(inbox.id)
    else
      # Use legacy assignment system
      # If conversation has a team, only consider team members for assignment
      allowed_agent_ids = team_id.present? ? team_member_ids_with_capacity : inbox.member_ids_with_assignment_capacity
      AutoAssignment::AgentAssignmentService.new(conversation: self, allowed_agent_ids: allowed_agent_ids).perform
    end
  end

  def conversation_status_changed_to_resolved_or_snoozed?
    inbox.auto_assignment_v2_enabled? && saved_change_to_status? && (resolved? || snoozed?)
  end

  def team_member_ids_with_capacity
    return [] if team.blank? || team.allow_auto_assign.blank?

    inbox.member_ids_with_assignment_capacity & team.members.ids
  end

  def should_run_auto_assignment?
    return false unless inbox.enable_auto_assignment?
    # Assignment V2: Resolved/snoozed conversations still have an assignee, so bypass the
    # assignee-blank check below. The AssignmentJob needs to run to rebalance assignments.
    return true if conversation_status_changed_to_resolved_or_snoozed?

    # run only if assignee is blank, doesn't have access to inbox, or is not online
    assignee.blank? || inbox.members.exclude?(assignee) || !assignee_online_for_assignment?
  end

  def assignee_online_for_assignment?
    return false if assignee_id.blank?

    OnlineStatusTracker.get_available_users(account_id)[assignee_id.to_s] == 'online'
  end

  # V2 only assigns unassigned conversations. Clear an offline/busy assignee on reopen so
  # AssignmentJob can claim the conversation for an online agent. Skip when nobody is online
  # so we do not orphan the conversation.
  def clear_offline_assignee_for_v2!
    return unless conversation_status_changed_to_open?
    return if assignee_id.blank?
    return if assignee_online_for_assignment?
    return if inbox.available_agents.empty?

    update_columns(assignee_id: nil) # rubocop:disable Rails/SkipsModelValidations
  end
end
