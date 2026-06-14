<script setup>
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAgentConversations } from 'dashboard/composables/useAgentConversations';
import AgentRow from './AgentRow.vue';

defineProps({
  activeConversationId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['selectConversation']);

const { t } = useI18n();

const {
  sortedAgents,
  expandedAgentId,
  fetchAssigneeCounts,
  getAssigneeCount,
  getAgentConversations,
  isAgentLoading,
  toggleAgent,
} = useAgentConversations();

onMounted(() => {
  fetchAssigneeCounts();
});
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-full h-full overflow-y-auto border-e border-n-weak md:w-80 bg-n-background"
  >
    <header class="px-4 py-4 border-b border-n-weak">
      <h1 class="text-base font-medium text-n-slate-12">
        {{ t('AGENT_CONVERSATIONS.HEADER') }}
      </h1>
    </header>
    <span
      v-if="!sortedAgents.length"
      class="px-4 py-6 text-sm text-center text-n-slate-11"
    >
      {{ t('AGENT_CONVERSATIONS.NO_AGENTS') }}
    </span>
    <AgentRow
      v-for="agent in sortedAgents"
      :key="agent.id"
      :agent="agent"
      :count="getAssigneeCount(agent.id)"
      :is-expanded="expandedAgentId === agent.id"
      :is-loading="isAgentLoading(agent.id)"
      :conversations="getAgentConversations(agent.id)"
      :active-conversation-id="activeConversationId"
      @toggle="toggleAgent"
      @select-conversation="id => emit('selectConversation', id)"
    />
  </div>
</template>
