<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['continue']);
</script>

<template>
  <div class="w-full max-w-lg mx-auto">
    <div
      class="bg-white shadow dark:bg-n-solid-2 p-11 sm:shadow-lg sm:rounded-lg"
    >
      <div class="mb-6">
        <h2 class="text-2xl font-semibold text-n-slate-12">
          {{ $t('SESSION_REPLACED.TITLE') }}
        </h2>
        <p class="text-sm text-n-slate-11 mt-2">
          {{ $t('SESSION_REPLACED.DESCRIPTION') }}
        </p>
      </div>

      <NextButton
        lg
        type="button"
        class="w-full"
        :label="$t('SESSION_REPLACED.CONTINUE')"
        @click="() => emit('continue')"
      />
    </div>
  </div>
</template>
