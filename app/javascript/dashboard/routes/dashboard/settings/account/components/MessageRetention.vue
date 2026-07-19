<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DurationInput from 'next/input/DurationInput.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const MINIMUM_RETENTION_MINUTES = 1440;

const { t } = useI18n();
const duration = ref(0);
const unit = ref(DURATION_UNITS.DAYS);
const isEnabled = ref(false);
const isSubmitting = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const { message_retention_after: messageRetentionAfter } =
      currentAccount.value?.settings || {};

    duration.value = messageRetentionAfter;

    if (duration.value) {
      if (duration.value % (24 * 60) === 0) {
        unit.value = DURATION_UNITS.DAYS;
      } else if (duration.value % 60 === 0) {
        unit.value = DURATION_UNITS.HOURS;
      } else {
        unit.value = DURATION_UNITS.MINUTES;
      }
      isEnabled.value = true;
    } else {
      isEnabled.value = false;
    }
  },
  { deep: true, immediate: true }
);

const updateAccountSettings = async settings => {
  try {
    isSubmitting.value = true;
    await updateAccount(settings, { silent: true });
    useAlert(t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

const handleSubmit = async () => {
  if (duration.value < MINIMUM_RETENTION_MINUTES) {
    useAlert(t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.DURATION.ERROR'));
    return Promise.resolve();
  }

  return updateAccountSettings({
    message_retention_after: duration.value,
  });
};

const handleDisable = async () => {
  duration.value = null;

  return updateAccountSettings({
    message_retention_after: null,
  });
};

const toggleMessageRetention = async () => {
  if (!isEnabled.value) handleDisable();
};
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <div class="flex justify-between items-center w-full">
        <h3 class="text-heading-2 text-n-slate-12">
          {{ t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.TITLE') }}
        </h3>
        <div class="flex justify-end">
          <Switch v-model="isEnabled" @change="toggleMessageRetention" />
        </div>
      </div>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.NOTE') }}
      </p>
    </div>

    <div v-if="isEnabled" class="px-5 py-4">
      <form class="grid gap-5" @submit.prevent="handleSubmit">
        <WithLabel
          :label="t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.DURATION.LABEL')"
          :help-message="
            t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.DURATION.HELP')
          "
        >
          <div class="gap-2 w-full grid grid-cols-[3fr_1fr]">
            <DurationInput
              v-model="duration"
              v-model:unit="unit"
              min="0"
              max="1438560"
              class="w-full"
            />
          </div>
        </WithLabel>
        <div class="flex gap-2">
          <NextButton
            blue
            type="submit"
            :is-loading="isSubmitting"
            :label="t('CONVERSATION_WORKFLOW.MESSAGE_RETENTION.UPDATE_BUTTON')"
          />
        </div>
      </form>
    </div>
  </div>
</template>
