<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { IMAGE_TYPES, MAX_COPIES_PER_ADD, useBoardGameStore } from '~/composables/useBoardGameStore'
import type { GameInput } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const route = useRoute()
const gameId = computed(() => String(route.params.id))
const isNew = computed(() => gameId.value === 'new')

// Pages that link here (e.g. a category page) pass ?from= so "back" returns there.
// Only in-app employee paths are honoured, so the link can't point off-site.
const backTo = computed(() => {
  const from = String(route.query.from ?? '')
  return from.startsWith('/employee/') ? from : '/employee/games'
})
const backLabel = computed(() =>
  backTo.value.startsWith('/employee/categories/') ? '← กลับไปหน้าหมวดหมู่' : '← กลับไปหน้าจัดการเกม')

const {
  categories, loading, getGame, createGame, updateGame, deleteGame, gameHasHistory, activeBookingCountForGame,
  uploadGameImage, deleteGameImage
} = useBoardGameStore()
const { addToast } = useToasts()

const game = computed(() => {
  if (isNew.value) return undefined
  const g = getGame(gameId.value)
  return g && !g.archived ? g : undefined
})

const form = ref({
  name: '',
  image: null as string | null,
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
const uploading = ref(false)

/**
 * Uploads straight away so the employee can see the cover before committing, but
 * only puts the URL in the form — the game row is written when they press save.
 */
async function onPickImage(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''  // reset, so picking the same file again still fires change
  if (!file || uploading.value) return

  uploading.value = true
  const { url, error } = await uploadGameImage(file)
  uploading.value = false

  if (!url) {
    addToast(error ?? 'อัปโหลดรูปไม่สำเร็จ', true)
    return
  }
  form.value.image = url
  addToast('อัปโหลดรูปแล้ว กด "บันทึกการแก้ไข" เพื่อยืนยัน', false)
}

function removeImage() {
  form.value.image = null
  addToast('เอารูปออกแล้ว กด "บันทึกการแก้ไข" เพื่อยืนยัน', false)
}

// Fill the form once per game. Stock changes reload the data, and refilling on every
// reload would wipe edits the employee hasn't saved yet.
const filledFor = ref<string | null>(null)
watch(game, g => {
  if (!g || filledFor.value === g.id) return
  form.value = {
    name: g.name,
    image: g.image ?? null,
    description: g.description,
    minP: g.minP,
    maxP: g.maxP,
    playtime: g.playtime,
    categoryIds: g.categories.map(c => c.id),
    howToPlay: g.howToPlay.join('\n')
  }
  filledFor.value = g.id
}, { immediate: true })

// "+ สร้างเกมใหม่ในหมวดนี้" arrives with ?category=; tick it once categories have loaded.
watch(() => categories.length, () => {
  const preset = String(route.query.category ?? '')
  if (isNew.value && preset && !form.value.categoryIds.length && categories.some(c => c.id === preset)) {
    form.value.categoryIds = [preset]
  }
}, { immediate: true })

// The stock panel stages its own changes; save() commits them along with the form.
const stock = ref<{ changeSummary: string[], apply: () => Promise<string | null> } | null>(null)
const stockPending = computed(() => stock.value?.changeSummary ?? [])

const activeCount = computed(() => (game.value ? activeBookingCountForGame(game.value.id) : 0))
const hasHistory = computed(() => !!game.value && gameHasHistory(game.value.id))
const canDelete = computed(() => !!game.value && activeCount.value === 0)

function toInput(): GameInput {
  return {
    name: form.value.name,
    image: form.value.image,
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
    await navigateTo({ path: `/employee/games/${id}`, query: route.query.from ? { from: backTo.value } : {} })
    return
  }

  const previousImage = game.value?.image ?? null
  const { error } = await updateGame(gameId.value, toInput())
  if (error) {
    saving.value = false
    errorMessage.value = error
    return
  }

  // Boxes live in game_copy, so they are applied only once the game row itself saved.
  const stockError = (await stock.value?.apply()) ?? null
  saving.value = false
  if (stockError) {
    errorMessage.value = stockError
    return
  }
  // Only once the row has stopped pointing at it: deleting earlier would leave the
  // game showing a file that no longer exists if the save then failed.
  if (previousImage && previousImage !== form.value.image) await deleteGameImage(previousImage)
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
  await navigateTo(backTo.value)
}
</script>

<template>
  <main>
    <NuxtLink :to="backTo" class="back-link">{{ backLabel }}</NuxtLink>

    <p v-if="!isNew && !game" class="empty-row">{{ loading ? 'กำลังโหลดข้อมูลเกม...' : 'ไม่พบเกมนี้' }}</p>

    <template v-else>
      <div class="section-head">
        <h2>{{ isNew ? 'เพิ่มเกมใหม่' : `แก้ไข ${game?.name}` }}</h2>
      </div>

      <form class="panel form-panel" @submit.prevent="save">
        <div v-if="errorMessage" class="err">{{ errorMessage }}</div>

        <div class="field">
          <label for="game-name">ชื่อเกม</label>
          <input id="game-name" v-model="form.name" type="text" maxlength="150" required>
        </div>

        <div class="field">
          <label>รูปหน้ากล่อง <span class="optional">(ไม่บังคับ)</span></label>
          <div class="image-field">
            <div class="image-preview">
              <GameImage :src="form.image || undefined" :alt="form.name || 'ยังไม่มีรูป'" />
            </div>
            <div class="image-actions">
              <!-- The file input is hidden; its <label> is the visible control. -->
              <input
                id="game-image"
                type="file"
                class="sr-only"
                :accept="IMAGE_TYPES.join(',')"
                :disabled="uploading"
                @change="onPickImage"
              >
              <div class="cell-actions">
                <label for="game-image" class="btn btn-ghost btn-sm">
                  {{ uploading ? 'กำลังอัปโหลด...' : form.image ? 'เปลี่ยนรูป' : 'เลือกรูป' }}
                </label>
                <button v-if="form.image" class="btn btn-ghost btn-sm" type="button" @click="removeImage">
                  เอารูปออก
                </button>
              </div>
              <p class="dim-text">JPG, PNG หรือ WebP · ไม่เกิน 5 MB · รูปจะถูกเก็บใน Supabase Storage</p>
            </div>
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

        <!-- Enter still submits; the visible button lives in the save bar below,
             because it now commits the stock panel as well. -->
        <button class="sr-only" type="submit" tabindex="-1" aria-hidden="true" />
      </form>

      <StockManager v-if="game" ref="stock" :game-id="game.id" />

      <div class="save-bar">
        <p v-if="stockPending.length" class="save-bar-note">
          รอบันทึก: {{ stockPending.join(' · ') }}
        </p>
        <p v-else class="save-bar-note dim-text">การแก้ไขทั้งหน้านี้จะมีผลเมื่อกดบันทึก</p>
        <button class="btn btn-primary btn-lg" type="button" :disabled="saving" @click="save">
          {{ saving ? 'กำลังบันทึก...' : isNew ? 'สร้างเกม' : 'บันทึกการแก้ไข' }}
        </button>
      </div>

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
