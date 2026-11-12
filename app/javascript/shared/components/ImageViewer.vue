<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue';

defineProps({
  src: {
    type: String,
    required: true,
  },
});

const emit = defineEmits(['close']);

const isZoomed = ref(false);

const onKeydown = event => {
  if (event.key === 'Escape') emit('close');
};

onMounted(() => document.addEventListener('keydown', onKeydown));
onBeforeUnmount(() => document.removeEventListener('keydown', onKeydown));
</script>

<template>
  <Teleport to="body">
    <div
      class="fixed inset-0 z-[9999] overflow-auto bg-[rgb(0_0_0/0.9)]"
      @click.self="emit('close')"
    >
      <button
        type="button"
        class="fixed top-3 z-10 flex items-center justify-center rounded-full size-9 ltr:right-3 rtl:left-3 bg-white/20 text-white hover:bg-white/30"
        :aria-label="$t('CHAT_FORM.CLOSE')"
        @click="emit('close')"
      >
        <span class="i-lucide-x size-5" />
      </button>
      <div class="flex min-h-full p-4" @click.self="emit('close')">
        <img
          :src="src"
          alt=""
          class="m-auto rounded-lg"
          :class="
            isZoomed
              ? 'max-w-none w-[200vw] cursor-zoom-out'
              : 'max-w-full max-h-[calc(100vh-2rem)] object-contain cursor-zoom-in'
          "
          @click="isZoomed = !isZoomed"
        />
      </div>
    </div>
  </Teleport>
</template>
