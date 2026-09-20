<script setup lang="ts">
import { computed } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

// Read-only: the clock shows the device's real time and can't be changed from the UI.
const { simNow } = useBoardGameStore()

// e.g. "Asia/Bangkok" — makes it obvious which clock the times on screen belong to.
const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone

// e.g. "ศ. 20 ก.ย. 2569" — Thai weekday and month with the Buddhist-era year.
const dateFormat = new Intl.DateTimeFormat('th-TH', {
  weekday: 'short', day: 'numeric', month: 'short', year: 'numeric'
})

const nowDate = computed(() => dateFormat.format(simNow.value))
const nowTime = computed(() => simNow.value.toTimeString().slice(0, 5))
</script>

<template>
  <header class="top">
    <NuxtLink to="/" class="brand">
      <div class="mark">🐍</div>
      <div class="titles">
        <h1>ระบบจองบอร์ดเกม</h1>
        <p>เลือกเกม เช็คคิว แล้วจองได้ทันที</p>
      </div>
    </NuxtLink>
    <div class="header-right">
      <div class="clock-box">
        <span class="lbl">เวลาปัจจุบัน</span>
        <span class="clock-date">{{ nowDate }}</span>
        <span class="clock-time">{{ nowTime }}</span>
        <span class="tz">{{ timeZone }}</span>
      </div>
    </div>
  </header>
</template>
