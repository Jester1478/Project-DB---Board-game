<script setup lang="ts">
import type { NuxtError } from '#app'

const props = defineProps<{ error: NuxtError }>()

const notFound = computed(() => props.error.statusCode === 404)

// clearError, not a plain link: the app stays in its error state until it is cleared.
function goHome() {
  void clearError({ redirect: '/' })
}
</script>

<template>
  <main class="error-page">
    <p class="error-code">{{ notFound ? '404' : 'เกิดข้อผิดพลาด' }}</p>
    <h1>{{ notFound ? 'ไม่พบหน้านี้' : 'หน้านี้เปิดไม่ได้ในขณะนี้' }}</h1>
    <p class="dim-text">
      {{ notFound ? 'ลิงก์อาจพิมพ์ผิด หรือหน้านี้ถูกย้ายไปแล้ว' : 'กรุณาลองใหม่อีกครั้ง หากยังไม่ได้ ให้กลับไปเริ่มจากหน้าแรก' }}
    </p>
    <button class="btn btn-primary btn-lg" type="button" @click="goHome">กลับหน้าแคตตาล็อก</button>
  </main>
</template>
