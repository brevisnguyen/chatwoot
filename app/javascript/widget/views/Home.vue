<script>
import TeamAvailability from 'widget/components/TeamAvailability.vue';
import { mapGetters, mapActions } from 'vuex';
import { useRouter } from 'vue-router';
import configMixin from 'widget/mixins/configMixin';
import ArticleContainer from '../components/pageComponents/Home/Article/ArticleContainer.vue';
export default {
  name: 'Home',
  components: {
    ArticleContainer,
    TeamAvailability,
  },
  mixins: [configMixin],
  setup() {
    const router = useRouter();
    return { router };
  },
  computed: {
    ...mapGetters({
      availableAgents: 'agent/availableAgents',
      conversationSize: 'conversation/getConversationSize',
      unreadMessageCount: 'conversation/getUnreadMessageCount',
      conversationParams: 'conversationAttributes/getConversationParams',
      isCreatingConversation: 'conversation/getIsCreating',
    }),
    hasConversation() {
      return !!(this.conversationSize || this.conversationParams?.id);
    },
    // Resolved + allow_messages_after_resolved off → cannot continue; must start new
    mustStartNewConversation() {
      const { allowMessagesAfterResolved } = window.chatwootWebChannel;
      return (
        this.hasConversation &&
        !allowMessagesAfterResolved &&
        this.conversationParams?.status === 'resolved'
      );
    },
    canContinueConversation() {
      return this.hasConversation && !this.mustStartNewConversation;
    },
  },
  methods: {
    ...mapActions('conversation', ['createConversation', 'clearConversations']),
    ...mapActions('conversationAttributes', ['clearConversationAttributes']),
    async startConversation() {
      if (this.isCreatingConversation) {
        return;
      }

      const shouldStartNew =
        !this.hasConversation || this.mustStartNewConversation;

      if (this.preChatFormEnabled && shouldStartNew) {
        await this.router.replace({ name: 'prechat-form' });
        return;
      }

      if (shouldStartNew) {
        if (this.mustStartNewConversation) {
          this.clearConversations();
          this.clearConversationAttributes();
        }
        await this.createConversation({});
      }

      await this.router.replace({ name: 'messages' });
    },
  },
};
</script>

<template>
  <div class="z-50 flex flex-col justify-end flex-1 w-full p-4 gap-4">
    <TeamAvailability
      :available-agents="availableAgents"
      :has-conversation="canContinueConversation"
      :unread-count="unreadMessageCount"
      @start-conversation="startConversation"
    />

    <ArticleContainer />
  </div>
</template>
