<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { CONTENT_TYPES } from '../constants.js';
import { useMessageContext } from '../provider.js';
import { useInbox } from 'dashboard/composables/useInbox';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

const { content, contentAttributes, contentType } = useMessageContext();
const { t } = useI18n();
const { isAWebWidgetInbox } = useInbox();

const cardHeader = computed(() => {
  const { mediaUrl, title, description } = contentAttributes.value || {};
  if (!mediaUrl && !title && !description) return null;

  const normalizedDescription = (description || '').replace(
    /<br\s*\/?>/gi,
    '\n'
  );
  return {
    mediaUrl,
    title,
    description: description
      ? new MessageFormatter(normalizedDescription).formattedMessage
      : '',
  };
});

const formValues = computed(() => {
  if (contentType.value === CONTENT_TYPES.FORM) {
    const { items, submittedValues = [] } = contentAttributes.value;

    if (submittedValues.length) {
      return submittedValues.map(submittedValue => {
        const item = items.find(
          formItem => formItem.name === submittedValue.name
        );
        return {
          title: submittedValue.value,
          value: submittedValue.value,
          label: item?.label,
          type: item?.type,
          fileUrl: submittedValue.fileUrl,
        };
      });
    }

    return [];
  }

  if (contentType.value === CONTENT_TYPES.INPUT_SELECT) {
    const [item] = contentAttributes.value?.submittedValues ?? [];
    if (!item) return [];

    return [
      {
        title: item.title,
        value: item.value,
        label: '',
      },
    ];
  }

  return [];
});
</script>

<template>
  <BaseBubble class="px-4 py-3" data-bubble-name="csat">
    <div v-if="cardHeader" class="mb-2">
      <img
        v-if="cardHeader.mediaUrl"
        :src="cardHeader.mediaUrl"
        alt=""
        class="w-full object-contain max-h-[150px] rounded-lg mb-2"
      />
      <h4 v-if="cardHeader.title" class="text-base font-medium text-n-slate-12">
        {{ cardHeader.title }}
      </h4>
      <div
        v-if="cardHeader.description"
        v-dompurify-html="cardHeader.description"
        class="text-sm text-n-slate-11"
      />
    </div>
    <span v-dompurify-html="content" :title="content" />
    <dl v-if="formValues.length" class="mt-4">
      <template v-for="item in formValues" :key="item.title">
        <dt class="text-n-slate-11 italic mt-2">
          {{ item.label || t('CONVERSATION.RESPONSE') }}
        </dt>
        <dd v-if="item.type === 'image' && item.fileUrl">
          <a
            :href="item.fileUrl"
            target="_blank"
            rel="noreferrer noopener nofollow"
            class="inline-block mt-1"
          >
            <img
              :src="item.fileUrl"
              alt=""
              class="max-w-[200px] max-h-[200px] rounded-lg object-cover"
            />
          </a>
        </dd>
        <dd v-else>{{ item.title }}</dd>
      </template>
    </dl>
    <div v-else-if="isAWebWidgetInbox" class="my-2 font-medium">
      {{ t('CONVERSATION.NO_RESPONSE') }}
    </div>
  </BaseBubble>
</template>
