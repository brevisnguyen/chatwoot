<script setup>
import { computed, ref } from 'vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import ChatForm from 'shared/components/ChatForm.vue';
import ImageViewer from 'shared/components/ImageViewer.vue';

const props = defineProps({
  mediaUrl: {
    type: String,
    default: '',
  },
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
  submittedValues: {
    type: Array,
    default: () => [],
  },
});

defineEmits(['submit']);

const { formatMessage } = useMessageFormatter();

const showMediaViewer = ref(false);

const normalizedDescription = computed(() =>
  (props.description || '').replace(/<br\s*\/?>/gi, '\n')
);
</script>

<template>
  <div
    class="card-form chat-bubble agent bg-n-background dark:bg-n-solid-3 w-full max-w-80 rounded-lg overflow-hidden"
  >
    <button
      v-if="mediaUrl"
      type="button"
      class="relative block w-full cursor-zoom-in"
      @click="showMediaViewer = true"
    >
      <img class="w-full h-auto object-contain max-h-80" :src="mediaUrl" />
      <span
        class="absolute bottom-2 flex items-center gap-1 px-2 py-1 text-xs text-white rounded-full ltr:right-2 rtl:left-2 bg-black/60"
      >
        <span class="i-lucide-zoom-in size-3.5" />
        {{ $t('CHAT_FORM.VIEW_IMAGE') }}
      </span>
    </button>
    <ImageViewer
      v-if="showMediaViewer"
      :src="mediaUrl"
      @close="showMediaViewer = false"
    />
    <div class="pt-4">
      <h4
        v-if="title"
        class="!text-base !font-medium !mt-1 !mb-1 !leading-[1.5] text-n-slate-12"
      >
        {{ title }}
      </h4>
      <div
        v-if="description"
        v-dompurify-html="formatMessage(normalizedDescription, false)"
        class="!mb-2 text-sm text-n-slate-11"
      />
      <ChatForm
        embedded
        :items="items"
        :button-label="buttonLabel"
        :submitted-values="submittedValues"
        @submit="$emit('submit', $event)"
      />
    </div>
  </div>
</template>
