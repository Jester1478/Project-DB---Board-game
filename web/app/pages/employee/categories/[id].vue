<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { isUsableCopy, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Game } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const route = useRoute()
const categoryId = computed(() => String(route.params.id))

const { categories, catalogGames, loading, loadError, addGameToCategory, removeGameFromCategory } = useBoardGameStore()
const { addToast } = useToasts()

const category = computed(() => categories.find(c => c.id === categoryId.value))

const isInCategory = (game: Game) => game.categories.some(c => c.id === categoryId.value)
const games = computed(() => catalogGames.value.filter(isInCategory))
const otherGames = computed(() => catalogGames.value.filter(g => !isInCategory(g)))

// Game pages opened from here come back here afterwards (see ?from= on the game page).
const selfPath = computed(() => `/employee/categories/${categoryId.value}`)
const editLink = (game: Game) => ({ path: `/employee/games/${game.id}`, query: { from: selfPath.value } })
const newGameLink = computed(() => ({ path: '/employee/games/new', query: { category: categoryId.value, from: selfPath.value } }))

function otherCategoryNames(game: Game) {
  return game.categories.filter(c => c.id !== categoryId.value).map(c => c.name).join(', ')
}

function usableCount(game: Game) {
  return game.copies.filter(isUsableCopy).length
}

const pickedGameId = ref('')
const busy = ref(false)

async function add() {
  const game = otherGames.value.find(g => g.id === pickedGameId.value)
  if (!game || !category.value || busy.value) return
  busy.value = true
  const { error } = await addGameToCategory(game.id, category.value.id)
  busy.value = false
  if (error) return addToast(error, true)
  pickedGameId.value = ''
  addToast(`เพิ่ม "${game.name}" เข้าหมวด "${category.value.name}" แล้ว`, false)
}

async function remove(game: Game) {
  if (!category.value || busy.value) return
  if (!confirm(`เอา "${game.name}" ออกจากหมวด "${category.value.name}"?\nเกมจะไม่ถูกลบ แค่ไม่อยู่ในหมวดนี้แล้ว`)) return
  busy.value = true
  const { error } = await removeGameFromCategory(game.id, category.value.id)
  busy.value = false
  addToast(error ?? `เอา "${game.name}" ออกจากหมวด "${category.value.name}" แล้ว`, !!error)
}
</script>

<template>
  <main>
    <NuxtLink to="/employee/categories" class="back-link">← กลับไปหน้าหมวดหมู่</NuxtLink>

    <p v-if="loadError" class="err">{{ loadError }}</p>
    <p v-if="!category" class="empty-row">{{ loading ? 'กำลังโหลด...' : 'ไม่พบหมวดหมู่นี้' }}</p>

    <template v-else>
      <div class="section-head section-head-row">
        <div>
          <h2>หมวดหมู่: {{ category.name }}</h2>
          <p>มีเกมในหมวดนี้ {{ games.length }} เกม กดชื่อเกมเพื่อแก้ไข</p>
        </div>
        <NuxtLink :to="newGameLink" class="btn btn-primary btn-lg">+ สร้างเกมใหม่ในหมวดนี้</NuxtLink>
      </div>

      <form class="panel form-panel" @submit.prevent="add">
        <label class="field-label" for="pick-game">เพิ่มเกมที่มีอยู่แล้วเข้าหมวดนี้</label>
        <div v-if="otherGames.length" class="inline-form">
          <select id="pick-game" v-model="pickedGameId" class="inline-select">
            <option value="" disabled>— เลือกเกม —</option>
            <option v-for="g in otherGames" :key="g.id" :value="g.id">{{ g.icon }} {{ g.name }}</option>
          </select>
          <button class="btn btn-primary btn-sm" type="submit" :disabled="busy || !pickedGameId">+ เพิ่มเข้าหมวด</button>
        </div>
        <p v-else class="dim-text">ทุกเกมอยู่ในหมวดนี้แล้ว</p>
      </form>

      <table class="book-table">
        <thead>
          <tr><th>เกม</th><th>ผู้เล่น · เวลา</th><th>สต๊อก</th><th>หมวดอื่น</th><th /></tr>
        </thead>
        <tbody>
          <tr v-for="g in games" :key="g.id">
            <td><NuxtLink :to="editLink(g)" class="name-link">{{ g.icon }} {{ g.name }}</NuxtLink></td>
            <td>{{ g.minP }}-{{ g.maxP }} คน · {{ g.playtime }} นาที</td>
            <td>พร้อมให้บริการ {{ usableCount(g) }} กล่อง</td>
            <td>{{ otherCategoryNames(g) || '—' }}</td>
            <td class="cell-right">
              <div class="cell-actions">
                <NuxtLink :to="editLink(g)" class="btn btn-ghost btn-sm">แก้ไข</NuxtLink>
                <button class="btn btn-ghost btn-sm" type="button" :disabled="busy" @click="remove(g)">เอาออกจากหมวด</button>
              </div>
            </td>
          </tr>
          <tr v-if="!games.length">
            <td colspan="5" class="empty-row">{{ loading ? 'กำลังโหลด...' : 'ยังไม่มีเกมในหมวดนี้' }}</td>
          </tr>
        </tbody>
      </table>
    </template>
  </main>
</template>
