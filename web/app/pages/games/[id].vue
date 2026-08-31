<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const route = useRoute()
const gameId = computed(() => String(route.params.id))

const { getGame, copyStatus, bookingsForCopy } = useBoardGameStore()

const game = computed(() => getGame(gameId.value))

const howToPlayOpen = ref(false)
const showBookingModal = ref(false)

function fmtTime(d: Date) {
  return d.toTimeString().slice(0, 5)
}
</script>

<template>
  <main v-if="game">
    <NuxtLink to="/" class="back-link">← กลับไปหน้าแคตตาล็อก</NuxtLink>

    <!-- SECTION 1: hero + book button -->
    <section class="game-hero">
      <div class="game-hero-image">{{ game.icon }}</div>
      <div class="game-hero-info">
        <span class="cat">{{ game.category }}</span>
        <h2>{{ game.name }}</h2>
        <p class="game-hero-meta">{{ game.minP }}-{{ game.maxP }} ผู้เล่น · ~{{ game.playtime }} นาที/รอบ · {{ game.copies.length }} กล่อง</p>
        <button class="btn btn-primary btn-lg" @click="showBookingModal = true">จองคิว</button>
      </div>
    </section>

    <!-- SECTION 2: how to play accordion -->
    <section class="panel">
      <button class="panel-header" @click="howToPlayOpen = !howToPlayOpen">
        <span>📖 วิธีเล่น</span>
        <span class="chevron" :class="{ open: howToPlayOpen }">⌄</span>
      </button>
      <div v-if="howToPlayOpen" class="panel-body">
        <ol class="howto-list">
          <li v-for="(step, i) in game.howToPlay" :key="i">{{ step }}</li>
        </ol>
      </div>
    </section>

    <!-- SECTION 3: booking status per copy -->
    <section class="panel">
      <div class="panel-header static">
        <span>📋 สถานะการจอง</span>
      </div>
      <div class="panel-body">
        <div v-for="copy in game.copies" :key="copy.id" class="copy-row">
          <div class="copy-row-head">
            <span class="name">{{ copy.label }}</span>
            <span class="state" :class="copyStatus(copy)">{{ copyStatus(copy) === 'free' ? 'ว่าง' : 'ไม่ว่าง' }}</span>
          </div>
          <div v-if="bookingsForCopy(copy.id).length" class="booking-chips">
            <span v-for="b in bookingsForCopy(copy.id)" :key="b.id" class="chip" :class="b.status">
              {{ fmtTime(b.start) }}–{{ fmtTime(b.end) }} · {{ b.status }}
            </span>
          </div>
          <p v-else class="empty-hint">ยังไม่มีการจองในขณะนี้ — ว่างพร้อมใช้งาน</p>
        </div>
      </div>
    </section>

    <BookingModal v-if="showBookingModal" :game-id="game.id" @close="showBookingModal = false" />
  </main>
  <main v-else>
    <p class="empty-row">ไม่พบเกมนี้</p>
  </main>
</template>
