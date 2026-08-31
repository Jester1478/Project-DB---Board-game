<script setup lang="ts">
import { useToasts } from '~/composables/useToasts'

const { toasts } = useToasts()
</script>

<template>
  <div class="toast-wrap">
    <div v-for="t in toasts" :key="t.id" class="toast" :class="{ error: t.isError }">
      {{ t.message }}
    </div>
  </div>
</template>
