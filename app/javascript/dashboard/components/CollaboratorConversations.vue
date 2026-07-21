<script setup>
import { ref, computed, provide } from 'vue';
import { useBreakpoints } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import ConversationItem from './ConversationItem.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import IntersectionObserver from 'dashboard/components/IntersectionObserver.vue';
import Avatar from 'next/avatar/Avatar.vue';
import {
  getAgentsByUpdatedPresence,
  getSortedAgentsByAvailability,
} from 'dashboard/helper/agentHelper';

import wootConstants from 'dashboard/constants/globals';

const props = defineProps({
  conversationList: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  showEndOfListMessage: { type: Boolean, default: false },
  label: { type: String, default: '' },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  conversationType: { type: String, default: '' },
  conversationStatus: { type: String, default: '' },
  showAssignee: { type: Boolean, default: false },
  isOnExpandedLayout: { type: Boolean, default: false },
});

const emit = defineEmits(['loadMore']);

const { t } = useI18n();

const agentList = useMapGetter('agents/getAgents');
const currentUser = useMapGetter('getCurrentUser');
const currentAccountId = useMapGetter('getCurrentAccountId');

const conversationListRef = ref(null);
const virtualListRef = ref(null);
const isContextMenuOpen = ref(false);

provide('contextMenuElementTarget', virtualListRef);
provide('toggleContextMenu', state => {
  isContextMenuOpen.value = state;
});

const breakpoints = useBreakpoints({
  lg: wootConstants.LARGE_SCREEN_BREAKPOINT,
});
const isLgScreen = breakpoints.greaterOrEqual('lg');
const showExpandedCards = computed(
  () => props.isOnExpandedLayout && isLgScreen.value
);

const intersectionObserverOptions = computed(() => ({
  root: conversationListRef.value,
  rootMargin: '100px 0px 100px 0px',
}));

const expandedGroups = ref([]);

const isGroupCollapsed = id => !expandedGroups.value.includes(id);

const toggleGroup = id => {
  if (expandedGroups.value.includes(id)) {
    expandedGroups.value = expandedGroups.value.filter(item => item !== id);
  } else {
    expandedGroups.value = [...expandedGroups.value, id];
  }
};

const STATUS_BADGE_CLASSES = {
  online: 'bg-n-teal-3 text-n-teal-11',
  busy: 'bg-n-amber-3 text-n-amber-11',
  offline: 'bg-n-slate-3 text-n-slate-11',
};

const statusBadgeClass = status =>
  STATUS_BADGE_CLASSES[status] || STATUS_BADGE_CLASSES.offline;

const statusLabel = status => {
  if (status === 'online') {
    return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.ONLINE');
  }
  if (status === 'busy') {
    return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.BUSY');
  }
  return t('PROFILE_SETTINGS.FORM.AVAILABILITY.STATUS.OFFLINE');
};

const groupedConversations = computed(() => {
  const conversationsByAgentId = new Map();
  props.conversationList.forEach(conversation => {
    const assigneeId = conversation.meta?.assignee?.id;
    if (!assigneeId) return;
    if (!conversationsByAgentId.has(assigneeId)) {
      conversationsByAgentId.set(assigneeId, []);
    }
    conversationsByAgentId.get(assigneeId).push(conversation);
  });

  const agentsWithPresence = getAgentsByUpdatedPresence(
    agentList.value || [],
    currentUser.value,
    currentAccountId.value
  );
  const otherAgents = agentsWithPresence.filter(
    agent => agent.id !== currentUser.value?.id
  );
  const sortedAgents = getSortedAgentsByAvailability(otherAgents);

  return sortedAgents.map(agent => ({
    id: agent.id,
    name: agent.name || '',
    thumbnail: agent.thumbnail || '',
    availabilityStatus: agent.availability_status || 'offline',
    conversations: conversationsByAgentId.get(agent.id) || [],
  }));
});

const loadMoreConversations = () => {
  emit('loadMore');
};

defineExpose({ conversationListRef });
</script>

<template>
  <div
    ref="conversationListRef"
    class="flex-1 min-h-0 overflow-y-auto conversations-list"
    :class="{ '!overflow-hidden': isContextMenuOpen }"
  >
    <div ref="virtualListRef">
      <div
        v-for="group in groupedConversations"
        :key="group.id"
        class="border-b border-n-weak last:border-b-0"
      >
        <button
          class="flex items-center w-full gap-2 px-3 py-2 text-left"
          @click="toggleGroup(group.id)"
        >
          <span
            class="i-lucide-chevron-right size-4 text-n-slate-11 transition-transform"
            :class="{ 'rotate-90': !isGroupCollapsed(group.id) }"
          />
          <Avatar
            :name="group.name"
            :src="group.thumbnail"
            :size="20"
            :status="group.availabilityStatus"
          />
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ group.name }}
          </span>
          <span
            class="shrink-0 px-1.5 py-0.5 rounded-md text-xxs font-medium"
            :class="statusBadgeClass(group.availabilityStatus)"
          >
            {{ statusLabel(group.availabilityStatus) }}
          </span>
          <span
            class="px-1.5 py-0.5 ml-auto rounded-md bg-n-slate-3 text-xxs text-n-slate-11"
          >
            {{ group.conversations.length }}
          </span>
        </button>
        <div v-show="!isGroupCollapsed(group.id)">
          <ConversationItem
            v-for="conversation in group.conversations"
            :key="conversation.id"
            :source="conversation"
            :label="label"
            :team-id="teamId"
            :folders-id="foldersId"
            :conversation-type="conversationType"
            :conversation-status="conversationStatus"
            :show-assignee="showAssignee"
            :show-expanded="showExpandedCards"
          />
        </div>
      </div>
    </div>
    <div v-if="isLoading" class="flex justify-center my-4">
      <Spinner class="text-n-brand" />
    </div>
    <p v-else-if="showEndOfListMessage" class="p-4 text-center text-n-slate-11">
      {{ $t('CHAT_LIST.EOF') }}
    </p>
    <IntersectionObserver
      v-else
      :options="intersectionObserverOptions"
      @observed="loadMoreConversations"
    />
  </div>
</template>
