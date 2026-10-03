<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  src?: string
  alt: string
}>()

// A missing or broken file falls back to the placeholder, not a broken-image box.
const failed = ref(false)
watch(() => props.src, () => { failed.value = false })
</script>

<template>
  <img v-if="src && !failed" :src="src" :alt="alt" @error="failed = true">
  <svg v-else class="image-placeholder" viewBox="0 0 24 24" fill="none" role="img" :aria-label="alt">
    <rect x="3" y="3" width="18" height="18" rx="4" stroke="currentColor" stroke-width="1.5" />
    <circle cx="8.6" cy="8.6" r="1.4" fill="currentColor" />
    <path
      d="M4 16.5 9 11.8l4.4 4.1 2.5-2.1 4.1 3.4"
      stroke="currentColor"
      stroke-width="1.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
  </svg>
</template>
