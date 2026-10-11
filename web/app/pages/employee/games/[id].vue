<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { onBeforeRouteLeave, useRoute } from 'vue-router'
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

/** The form as it stood when last loaded or saved; anything different is unsaved. */
const savedForm = ref(JSON.stringify(form.value))
const savedCopies = ref(initialCopies.value)

function markSaved() {
  savedForm.value = JSON.stringify(form.value)
  savedCopies.value = initialCopies.value
}
const errorMessage = ref('')
const saving = ref(false)
const deleting = ref(false)
const uploading = ref(false)
/** The picked file while the employee chooses its shape; null when the cropper is closed. */
const cropping = ref<File | null>(null)

function onPickImage(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''  // reset, so picking the same file again still fires change
  if (!file || uploading.value) return
  // Checked here because the cropper can only open what the browser can draw. Size
  // is checked after cropping instead: a large photo usually shrinks under the limit.
  if (!IMAGE_TYPES.includes(file.type)) return addToast('รองรับเฉพาะไฟล์ JPG, PNG และ WebP', true)
  cropping.value = file
}

/**
 * Uploads straight away so the employee can see the cover before committing, but
 * only puts the URL in the form — the game row is written when they press save.
 */
async function onCropped(file: File) {
  cropping.value = null
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
  markSaved()
}, { immediate: true })

// "+ สร้างเกมใหม่ในหมวดนี้" arrives with ?category=; tick it once categories have loaded.
watch(() => categories.length, () => {
  const preset = String(route.query.category ?? '')
  if (isNew.value && preset && !form.value.categoryIds.length && categories.some(c => c.id === preset)) {
    form.value.categoryIds = [preset]
    markSaved()  // arriving pre-ticked is the starting point, not an edit
  }
}, { immediate: true })

// The stock panel stages its own changes; save() commits them along with the form.
const stock = ref<{ changeSummary: string[], apply: () => Promise<string | null> } | null>(null)
const stockPending = computed(() => stock.value?.changeSummary ?? [])

// ---------- leaving with unsaved changes ----------

const dirty = computed(() =>
  JSON.stringify(form.value) !== savedForm.value
  || stockPending.value.length > 0
  || (isNew.value && initialCopies.value !== savedCopies.value))

/** Set while this page itself navigates (after creating or deleting), so the guard stays quiet. */
let leavingOnPurpose = false
/** Non-null while the "unsaved changes" dialog is open; called with the employee's choice. */
const answerLeave = ref<((choice: 'save' | 'discard' | 'stay') => void) | null>(null)

onBeforeRouteLeave(async () => {
  if (leavingOnPurpose || !dirty.value) return true
  const choice = await new Promise<'save' | 'discard' | 'stay'>(resolve => { answerLeave.value = resolve })
  answerLeave.value = null
  if (choice === 'stay') return false
  if (choice === 'save') {
    const ok = await save(false)
    if (!ok) addToast('บันทึกไม่สำเร็จ จึงยังอยู่ที่หน้านี้ กรุณาตรวจสอบข้อความด้านบนของฟอร์ม', true)
    return ok
  }

  // A cover uploaded but never saved belongs to no game; don't leave it in storage.
  const savedImage = game.value?.image ?? null
  if (form.value.image && form.value.image !== savedImage) void deleteGameImage(form.value.image)
  return true
})

// Closing the tab or refreshing can't show our own dialog; the browser's is the only option.
function warnOnUnload(event: BeforeUnloadEvent) {
  if (dirty.value) event.preventDefault()
}
onMounted(() => window.addEventListener('beforeunload', warnOnUnload))
onBeforeUnmount(() => window.removeEventListener('beforeunload', warnOnUnload))

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

/**
 * Returns whether everything was saved. `thenOpenGame` is false when the employee
 * is already on their way to another page and only wants the save.
 */
async function save(thenOpenGame = true): Promise<boolean> {
  if (saving.value) return false
  errorMessage.value = ''
  saving.value = true

  if (isNew.value) {
    const { error, id } = await createGame(toInput(), Number(initialCopies.value))
    saving.value = false
    if (!id) {
      errorMessage.value = error ?? 'สร้างเกมไม่สำเร็จ'
      return false
    }
    if (error) addToast(`สร้างเกมแล้ว แต่ตั้งค่าบางส่วนไม่สำเร็จ: ${error}`, true)
    else addToast(`เพิ่มเกม "${form.value.name.trim()}" แล้ว`, false)
    markSaved()
    if (thenOpenGame) {
      leavingOnPurpose = true
      await navigateTo({ path: `/employee/games/${id}`, query: route.query.from ? { from: backTo.value } : {} })
      leavingOnPurpose = false
    }
    return true
  }

  const previousImage = game.value?.image ?? null
  const { error } = await updateGame(gameId.value, toInput())
  if (error) {
    saving.value = false
    errorMessage.value = error
    return false
  }

  // Boxes live in game_copy, so they are applied only once the game row itself saved.
  const stockError = (await stock.value?.apply()) ?? null
  saving.value = false
  if (stockError) {
    errorMessage.value = stockError
    // The game's own fields did save; only the boxes are still pending.
    markSaved()
    return false
  }
  // Only once the row has stopped pointing at it: deleting earlier would leave the
  // game showing a file that no longer exists if the save then failed.
  if (previousImage && previousImage !== form.value.image) await deleteGameImage(previousImage)
  filledFor.value = null
  markSaved()
  addToast('บันทึกข้อมูลเกมแล้ว', false)
  return true
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
  leavingOnPurpose = true
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

      <form class="panel form-panel" @submit.prevent="save()">
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
              <p class="dim-text">JPG, PNG หรือ WebP · เลือกสัดส่วนและตำแหน่งได้หลังเลือกไฟล์ · รูปจะถูกเก็บใน Supabase Storage</p>
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

      <div v-if="answerLeave" class="overlay show">
        <div class="modal" role="alertdialog" aria-labelledby="leave-title">
          <h3 id="leave-title">ยังไม่ได้บันทึกการแก้ไข</h3>
          <p class="leave-text">
            {{ isNew ? 'เกมนี้ยังไม่ได้ถูกสร้าง' : 'การแก้ไขในหน้านี้ยังไม่ได้บันทึก' }}
            ถ้าออกตอนนี้ สิ่งที่แก้ไว้จะหายไป
          </p>
          <div class="leave-actions">
            <button class="btn btn-primary" type="button" @click="answerLeave('save')">
              {{ isNew ? 'สร้างเกมแล้วออก' : 'บันทึกแล้วออก' }}
            </button>
            <button class="btn btn-danger" type="button" @click="answerLeave('discard')">ออกโดยไม่บันทึก</button>
            <button class="btn btn-ghost" type="button" @click="answerLeave('stay')">อยู่หน้านี้ต่อ</button>
          </div>
        </div>
      </div>

      <ImageCropper v-if="cropping" :file="cropping" @confirm="onCropped" @cancel="cropping = null" />

      <StockManager v-if="game" ref="stock" :game-id="game.id" />

      <div class="save-bar">
        <p v-if="stockPending.length" class="save-bar-note">
          รอบันทึก: {{ stockPending.join(' · ') }}
        </p>
        <p v-else-if="dirty" class="save-bar-note">มีการแก้ไขที่ยังไม่ได้บันทึก</p>
        <p v-else class="save-bar-note dim-text">การแก้ไขทั้งหน้านี้จะมีผลเมื่อกดบันทึก</p>
        <button class="btn btn-primary btn-lg" type="button" :disabled="saving" @click="save()">
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
