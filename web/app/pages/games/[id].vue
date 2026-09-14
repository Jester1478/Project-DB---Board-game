<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useBoardGameStore } from '~/composables/useBoardGameStore'

const route = useRoute()
const gameId = computed(() => String(route.params.id))

const { getGame, usableCopies, copyStatus, bookingsForCopy, loading } = useBoardGameStore()

// An archived game's old link lands on "ไม่พบเกมนี้" rather than a bookable page.
const game = computed(() => {
  const g = getGame(gameId.value)
  return g && !g.archived ? g : undefined
})
// Damaged or lost boxes are hidden from customers entirely.
const copies = computed(() => (game.value ? usableCopies(game.value) : []))

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
      <div class="game-hero-image">
        <GameImage :src="game.image" :icon="game.icon" :alt="game.name" />
      </div>
      <div class="game-hero-info">
        <div v-if="game.categories.length" class="cat-list">
          <span v-for="c in game.categories" :key="c.id" class="cat">{{ c.name }}</span>
        </div>
        <h2>{{ game.name }}</h2>
        <p class="game-hero-meta">{{ game.minP }}-{{ game.maxP }} ผู้เล่น · ~{{ game.playtime }} นาที/รอบ · {{ copies.length }} กล่อง</p>
        <button v-if="copies.length" class="btn btn-primary btn-lg" @click="showBookingModal = true">จองคิว</button>
        <p v-else class="empty-hint">ขณะนี้ยังไม่มีกล่องให้บริการสำหรับเกมนี้</p>
      </div>
    </section>

    <!-- SECTION 2: how to play accordion -->
    <section class="panel">
      <button class="panel-header" @click="howToPlayOpen = !howToPlayOpen">
        <span>📖 วิธีเล่น</span>
        <span class="chevron" :class="{ open: howToPlayOpen }">⌄</span>
      </button>
      <div v-if="howToPlayOpen" class="panel-body">
        <ol v-if="game.howToPlay.length" class="howto-list">
          <li v-for="(step, i) in game.howToPlay" :key="i">{{ step }}</li>
        </ol>
        <p v-else class="empty-hint">ยังไม่มีข้อมูลวิธีเล่นสำหรับเกมนี้</p>
      </div>
    </section>

    <!-- SECTION 3: booking status per copy -->
    <section class="panel">
      <div class="panel-header static">
        <span>📋 สถานะการจอง</span>
      </div>
      <div class="panel-body">
        <div v-for="copy in copies" :key="copy.id" class="copy-row">
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
        <p v-if="!copies.length" class="empty-hint">ยังไม่มีกล่องให้บริการ</p>
      </div>
    </section>

    <BookingModal v-if="showBookingModal" :game-id="game.id" @close="showBookingModal = false" />
  </main>
  <main v-else>
    <NuxtLink to="/" class="back-link">← กลับไปหน้าแคตตาล็อก</NuxtLink>
    <p class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกมนี้' }}</p>
  </main>
</template>
