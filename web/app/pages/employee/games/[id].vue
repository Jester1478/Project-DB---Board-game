<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { MAX_COPIES_PER_ADD, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { GameInput } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const route = useRoute()
const gameId = computed(() => String(route.params.id))
const isNew = computed(() => gameId.value === 'new')

const { categories, loading, getGame, createGame, updateGame } = useBoardGameStore()
const { addToast } = useToasts()

const game = computed(() => (isNew.value ? undefined : getGame(gameId.value)))

const form = ref({ name: '', description: '', minP: 2, maxP: 4, playtime: 30, categoryId: '' })
const initialCopies = ref(1)
const errorMessage = ref('')
const saving = ref(false)

// Fill the form once per game. Stock changes reload the data, and refilling on every
// reload would wipe edits the employee hasn't saved yet.
const filledFor = ref<string | null>(null)
watch(game, g => {
  if (!g || filledFor.value === g.id) return
  form.value = {
    name: g.name,
    description: g.description,
    minP: g.minP,
    maxP: g.maxP,
    playtime: g.playtime,
    categoryId: g.categoryId ?? ''
  }
  filledFor.value = g.id
}, { immediate: true })

watch(() => categories.length, () => {
  if (isNew.value && !form.value.categoryId && categories[0]) form.value.categoryId = categories[0].id
}, { immediate: true })

function toInput(): GameInput {
  return {
    name: form.value.name,
    description: form.value.description,
    minP: Number(form.value.minP),
    maxP: Number(form.value.maxP),
    playtime: Number(form.value.playtime),
    categoryId: form.value.categoryId || null
  }
}

async function save() {
  if (saving.value) return
  errorMessage.value = ''
  saving.value = true

  if (isNew.value) {
    const { error, id } = await createGame(toInput(), Number(initialCopies.value))
    saving.value = false
    if (!id) {
      errorMessage.value = error ?? 'สร้างเกมไม่สำเร็จ'
      return
    }
    if (error) addToast(`สร้างเกมแล้ว แต่เพิ่มกล่องไม่สำเร็จ: ${error}`, true)
    else addToast(`เพิ่มเกม "${form.value.name.trim()}" แล้ว`, false)
    await navigateTo(`/employee/games/${id}`)
    return
  }

  const { error } = await updateGame(gameId.value, toInput())
  saving.value = false
  if (error) {
    errorMessage.value = error
    return
  }
  filledFor.value = null
  addToast('บันทึกข้อมูลเกมแล้ว', false)
}
</script>

<template>
  <main>
    <NuxtLink to="/employee/games" class="back-link">← กลับไปหน้าจัดการเกม</NuxtLink>

    <p v-if="!isNew && !game" class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกมนี้' }}</p>

    <template v-else>
      <div class="section-head">
        <h2>{{ isNew ? 'เพิ่มเกมใหม่' : `แก้ไข ${game?.name}` }}</h2>
        <p v-if="game" class="mono">{{ game.id }}</p>
        <p v-else>เกมใหม่จะแสดงไอคอน 🎲 และยังไม่มีวิธีเล่น จนกว่าจะเพิ่มในไฟล์ gamePresentation.ts</p>
      </div>

      <form class="panel form-panel" @submit.prevent="save">
        <div v-if="errorMessage" class="err">{{ errorMessage }}</div>

        <div class="field">
          <label>ชื่อเกม</label>
          <input v-model="form.name" type="text" maxlength="150" required>
        </div>
        <div class="field">
          <label>หมวดหมู่</label>
          <select v-model="form.categoryId">
            <option value="">— ไม่ระบุ —</option>
            <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
          </select>
        </div>
        <div class="field">
          <label>คำอธิบาย <span class="optional">(ไม่บังคับ)</span></label>
          <textarea v-model="form.description" rows="3" />
        </div>
        <div class="row3">
          <div class="field">
            <label>ผู้เล่นขั้นต่ำ</label>
            <input v-model.number="form.minP" type="number" min="1" step="1" required>
          </div>
          <div class="field">
            <label>ผู้เล่นสูงสุด</label>
            <input v-model.number="form.maxP" type="number" min="1" step="1" required>
          </div>
          <div class="field">
            <label>เวลาเล่น (นาที)</label>
            <input v-model.number="form.playtime" type="number" min="1" step="1" required>
          </div>
        </div>
        <div v-if="isNew" class="field">
          <label>จำนวนกล่องเริ่มต้น</label>
          <input v-model.number="initialCopies" type="number" min="0" :max="MAX_COPIES_PER_ADD" step="1">
        </div>

        <button class="btn btn-primary btn-lg" type="submit" :disabled="saving">
          {{ saving ? 'กำลังบันทึก...' : isNew ? 'สร้างเกม' : 'บันทึกการแก้ไข' }}
        </button>
      </form>

      <StockManager v-if="game" :game-id="game.id" />
    </template>
  </main>
</template>
