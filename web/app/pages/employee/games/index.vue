<script setup lang="ts">
import { computed, ref } from 'vue'
import { isUsableCopy, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Game } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const { catalogGames, archivedGames, loading, loadError, restoreGame } = useBoardGameStore()
const { addToast } = useToasts()

const restoringId = ref<string | null>(null)

const dateFormat = new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short', year: 'numeric' })

async function restore(game: Game) {
  if (restoringId.value) return
  if (!confirm(`กู้คืนเกม "${game.name}"?\nเกมจะกลับมาแสดงให้ลูกค้าจองได้อีกครั้ง พร้อมกล่องเดิม`)) return
  restoringId.value = game.id
  const { error } = await restoreGame(game.id)
  restoringId.value = null
  addToast(error ?? `กู้คืนเกม "${game.name}" แล้ว`, !!error)
}

const search = ref('')

const rows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return catalogGames.value.filter(g => `${g.name} ${categoryNames(g)}`.toLowerCase().includes(q))
})

function categoryNames(game: Game) {
  return game.categories.map(c => c.name).join(', ')
}

function stock(game: Game) {
  const usable = game.copies.filter(isUsableCopy).length
  return { usable, retired: game.copies.length - usable }
}
</script>

<template>
  <main>
    <div class="section-head section-head-row">
      <div>
        <h2>จัดการเกม</h2>
        <p>แก้ไขข้อมูลเกม เพิ่มเกมใหม่ และปรับจำนวนกล่องในสต๊อก</p>
      </div>
      <NuxtLink to="/employee/games/new" class="btn btn-primary btn-lg">+ เพิ่มเกมใหม่</NuxtLink>
    </div>

    <div class="employee-search">
      <input v-model="search" type="text" placeholder="ค้นหาด้วยชื่อเกม หรือหมวดหมู่...">
    </div>

    <p v-if="loadError" class="err">{{ loadError }}</p>

    <table class="book-table catalog-table">
      <thead>
        <tr><th>เกม</th><th>หมวดหมู่</th><th>ผู้เล่น · เวลา</th><th>สต๊อก</th><th /></tr>
      </thead>
      <tbody>
        <tr v-for="g in rows" :key="g.id">
          <td>{{ g.icon }} {{ g.name }}</td>
          <td>{{ categoryNames(g) || '—' }}</td>
          <td>{{ g.minP }}-{{ g.maxP }} คน · {{ g.playtime }} นาที</td>
          <td>
            พร้อมให้บริการ <strong>{{ stock(g).usable }}</strong> กล่อง
            <span v-if="stock(g).retired" class="dim"><br>งดให้บริการ {{ stock(g).retired }} กล่อง</span>
          </td>
          <td class="cell-right">
            <NuxtLink :to="`/employee/games/${g.id}`" class="btn btn-ghost btn-sm">แก้ไข</NuxtLink>
          </td>
        </tr>
        <tr v-if="!rows.length">
          <td colspan="5" class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกม' }}</td>
        </tr>
      </tbody>
    </table>

    <section v-if="archivedGames.length" class="booking-section archived-section">
      <div class="booking-section-head">
        <h3>เกมที่ลบแล้ว</h3>
        <span class="count-pill">{{ archivedGames.length }} เกม</span>
        <p class="dim-text">ซ่อนจากลูกค้าอยู่ ประวัติการจองยังเก็บไว้ครบ กดกู้คืนเพื่อให้กลับมาจองได้</p>
      </div>
      <table class="book-table">
        <thead>
          <tr><th>เกม</th><th>ลบเมื่อ</th><th>กล่อง</th><th /></tr>
        </thead>
        <tbody>
          <tr v-for="g in archivedGames" :key="g.id">
            <td>{{ g.icon }} {{ g.name }}</td>
            <td>{{ g.archivedAt ? dateFormat.format(g.archivedAt) : '—' }}</td>
            <td>{{ g.copies.length }} กล่อง</td>
            <td class="cell-right">
              <button class="btn btn-ghost btn-sm" type="button" :disabled="!!restoringId" @click="restore(g)">
                {{ restoringId === g.id ? 'กำลังกู้คืน...' : 'กู้คืน' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </main>
</template>
