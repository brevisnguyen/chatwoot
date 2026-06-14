import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/inbox/conversation';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import {
  getAgentsByUpdatedPresence,
  getSortedAgentsByAvailability,
} from 'dashboard/helper/agentHelper';

/**
 * Provides the data needed for the Agents overview page: the sorted agent list,
 * per-agent non-resolved conversation counts, and lazy-loaded conversations
 * assigned to each agent.
 */
export function useAgentConversations() {
  const verifiedAgents = useMapGetter('agents/getVerifiedAgents');
  const currentUser = useMapGetter('getCurrentUser');
  const currentAccountId = useMapGetter('getCurrentAccountId');

  const assigneeCounts = ref({});
  const expandedAgentId = ref(null);
  const conversationsByAgent = ref({});
  const loadingByAgent = ref({});

  const sortedAgents = computed(() => {
    const agentsWithPresence = getAgentsByUpdatedPresence(
      verifiedAgents.value || [],
      currentUser.value,
      currentAccountId.value
    );
    return getSortedAgentsByAvailability(agentsWithPresence);
  });

  const fetchAssigneeCounts = async () => {
    const { data } = await ConversationApi.assigneeSummary();
    assigneeCounts.value = data;
  };

  const getAssigneeCount = agentId => assigneeCounts.value[agentId] || 0;

  const getAgentConversations = agentId =>
    conversationsByAgent.value[agentId] || [];

  const isAgentLoading = agentId => Boolean(loadingByAgent.value[agentId]);

  const fetchAgentConversations = async agentId => {
    loadingByAgent.value = { ...loadingByAgent.value, [agentId]: true };
    try {
      const queryData = filterQueryGenerator([
        {
          attribute_key: 'assignee_id',
          filter_operator: 'equal_to',
          values: [agentId],
          query_operator: 'and',
        },
        {
          attribute_key: 'status',
          filter_operator: 'not_equal_to',
          values: ['resolved'],
          query_operator: 'and',
        },
      ]);
      const { data } = await ConversationApi.filter({ queryData, page: 1 });
      conversationsByAgent.value = {
        ...conversationsByAgent.value,
        [agentId]: data.payload,
      };
    } finally {
      loadingByAgent.value = { ...loadingByAgent.value, [agentId]: false };
    }
  };

  const toggleAgent = agentId => {
    if (expandedAgentId.value === agentId) {
      expandedAgentId.value = null;
      return;
    }
    expandedAgentId.value = agentId;
    if (!conversationsByAgent.value[agentId]) {
      fetchAgentConversations(agentId);
    }
  };

  return {
    sortedAgents,
    expandedAgentId,
    fetchAssigneeCounts,
    getAssigneeCount,
    getAgentConversations,
    isAgentLoading,
    toggleAgent,
  };
}
