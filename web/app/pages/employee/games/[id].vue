<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { DEFAULT_ICON, MAX_COPIES_PER_ADD, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { GameInput } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const route = useRoute()
const gameId = computed(() => String(route.params.id))
const isNew = computed(() => gameId.value === 'new')

const {
  categories, loading, getGame, createGame, updateGame, deleteGame, gameHasHistory, activeBookingCountForGame
} = useBoardGameStore()
const { addToast } = useToasts()

const game = computed(() => {
  if (isNew.value) return undefined
  const g = getGame(gameId.value)
  return g && !g.archived ? g : undefined
})

const form = ref({
  name: '',
  icon: DEFAULT_ICON,
  description: '',
  minP: 2,
  maxP: 4,
  playtime: 30,
  categoryIds: [] as string[],
  // One step per line; the store turns lines into how_to_play_step rows.
  howToPlay: ''
})
const initialCopies = ref(1)
const errorMessage = ref('')
const saving = ref(false)
const deleting = ref(false)

// Fill the form once per game. Stock changes reload the data, and refilling on every
// reload would wipe edits the employee hasn't saved yet.
const filledFor = ref<string | null>(null)
watch(game, g => {
  if (!g || filledFor.value === g.id) return
  form.value = {
    name: g.name,
    icon: g.icon,
    description: g.description,
    minP: g.minP,
    maxP: g.maxP,
    playtime: g.playtime,
    categoryIds: g.categories.map(c => c.id),
    howToPlay: g.howToPlay.join('\n')
  }
  filledFor.value = g.id
}, { immediate: true })

const activeCount = computed(() => (game.value ? activeBookingCountForGame(game.value.id) : 0))
const hasHistory = computed(() => !!game.value && gameHasHistory(game.value.id))
const canDelete = computed(() => !!game.value && activeCount.value === 0)

function toInput(): GameInput {
  return {
    name: form.value.name,
    icon: form.value.icon,
    description: form.value.description,
    minP: Number(form.value.minP),
    maxP: Number(form.value.maxP),
    playtime: Number(form.value.playtime),
    categoryIds: form.value.categoryIds,
    howToPlay: form.value.howToPlay.split('\n')
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
    if (error) addToast(`สร้างเกมแล้ว แต่ตั้งค่าบางส่วนไม่สำเร็จ: ${error}`, true)
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

async function remove() {
  if (!game.value || deleting.value) return
  const name = game.value.name
  const effect = hasHistory.value
    ? 'เกมจะหายไปจากหน้าเว็บ แต่ประวัติการจองเดิมยังเก็บไว้'
    : `ลบพร้อมกล่อง ${game.value.copies.length} กล่อง หมวดหมู่ และวิธีเล่น`
  if (!confirm(`ลบเกม "${name}"?\n${effect}\nกู้คืนจากหน้าเว็บไม่ได้`)) return

  deleting.value = true
  const { error, archived } = await deleteGame(game.value.id)
  deleting.value = false
  if (error) {
    addToast(error, true)
    return
  }
  addToast(archived ? `ลบเกม "${name}" แล้ว ประวัติการจองยังเก็บไว้` : `ลบเกม "${name}" แล้ว`, false)
  await navigateTo('/employee/games')
}
</script>

<template>
  <main>
    <NuxtLink to="/employee/games" class="back-link">← กลับไปหน้าจัดการเกม</NuxtLink>

    <p v-if="!isNew && !game" class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกมนี้' }}</p>

    <template v-else>
      <div class="section-head">
        <h2>{{ isNew ? 'เพิ่มเกมใหม่' : `แก้ไข ${game?.name}` }}</h2>
      </div>

      <form class="panel form-panel" @submit.prevent="save">
        <div v-if="errorMessage" class="err">{{ errorMessage }}</div>

        <div class="row-icon-name">
          <div class="field">
            <label>ไอคอน</label>
            <input v-model="form.icon" type="text" class="icon-input" aria-label="ไอคอนอีโมจิ">
          </div>
          <div class="field">
            <label>ชื่อเกม</label>
            <input v-model="form.name" type="text" maxlength="150" required>
          </div>
        </div>

        <div class="field">
          <label>หมวดหมู่ <span class="optional">(เลือกได้หลายหมวด)</span></label>
          <div class="check-list">
            <label v-for="c in categories" :key="c.id" class="check-item">
              <input v-model="form.categoryIds" type="checkbox" :value="c.id">
              {{ c.name }}
            </label>
          </div>
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

        <div class="field">
          <label>วิธีเล่น <span class="optional">(1 บรรทัดต่อ 1 ขั้นตอน)</span></label>
          <textarea v-model="form.howToPlay" rows="6" />
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

      <section v-if="game" class="panel form-panel danger-zone">
        <h3>ลบเกม</h3>
        <p v-if="!canDelete" class="dim-text">
          ลบไม่ได้ตอนนี้ เพราะยังมีการจองที่ยังไม่จบ {{ activeCount }} รายการ (จองไว้ กำลังใช้ หรือเกินกำหนด)
          ลบได้เมื่อการจองเหล่านั้นคืนเกมครบแล้ว
        </p>
        <p v-else-if="hasHistory" class="dim-text">
          เกมนี้เคยมีการจอง เมื่อลบ เกมจะหายไปจากหน้าลูกค้าและหน้าจัดการเกม แต่ประวัติการจองเดิมยังเก็บไว้ครบ
        </p>
        <p v-else class="dim-text">ลบเกมนี้พร้อมกล่อง หมวดหมู่ และวิธีเล่นทั้งหมด ลบแล้วกู้คืนไม่ได้</p>
        <button class="btn btn-danger btn-sm" type="button" :disabled="!canDelete || deleting" @click="remove">
          {{ deleting ? 'กำลังลบ...' : 'ลบเกมนี้' }}
        </button>
      </section>
    </template>
  </main>
</template>
