<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'

const props = defineProps<{ file: File }>()
const emit = defineEmits<{ (e: 'confirm', file: File): void, (e: 'cancel'): void }>()

/** Longest side of the saved picture. Covers are shown at 240px at most, so this is plenty. */
const MAX_OUTPUT_PX = 1600
const MAX_ZOOM = 3

const RATIOS = [
  { key: 'landscape', label: 'แนวนอน 4:3', value: 4 / 3 },
  { key: 'square', label: 'จัตุรัส 1:1', value: 1 },
  { key: 'portrait', label: 'แนวตั้ง 3:4', value: 3 / 4 },
  { key: 'original', label: 'ทั้งรูป', value: 0 }
] as const
type RatioKey = typeof RATIOS[number]['key']

const url = URL.createObjectURL(props.file)
onBeforeUnmount(() => URL.revokeObjectURL(url))

const img = ref<HTMLImageElement | null>(null)
const stage = ref<HTMLElement | null>(null)
const natural = ref<{ w: number, h: number } | null>(null)
const failed = ref(false)
const saving = ref(false)

const ratioKey = ref<RatioKey>('landscape')
const zoom = ref(1)
// The point of the picture that sits at the centre of the frame, as a 0–1 fraction
// of the picture. Kept in picture terms so it survives a change of ratio.
const centre = ref({ x: 0.5, y: 0.5 })

function onLoad() {
  const el = img.value!
  natural.value = { w: el.naturalWidth, h: el.naturalHeight }
}

const pictureRatio = computed(() => (natural.value ? natural.value.w / natural.value.h : 1))
/** Width ÷ height of the frame. "ทั้งรูป" takes the picture's own shape, so nothing is cut. */
const frameRatio = computed(() => RATIOS.find(r => r.key === ratioKey.value)!.value || pictureRatio.value)

/**
 * Everything below is measured with the frame's height as 1 unit, so the frame is
 * frameRatio wide. At zoom 1 the picture just covers the frame.
 */
const shown = computed(() => {
  const cover = Math.max(frameRatio.value / pictureRatio.value, 1)
  const h = cover * zoom.value
  return { w: pictureRatio.value * h, h }
})

function clamp(v: number, half: number) {
  return Math.min(1 - half, Math.max(half, v))
}

/** Keeps the frame inside the picture, so no empty band can be saved. */
function settle() {
  centre.value = {
    x: clamp(centre.value.x, frameRatio.value / (2 * shown.value.w)),
    y: clamp(centre.value.y, 1 / (2 * shown.value.h))
  }
}
watch([frameRatio, zoom], settle)

const pictureStyle = computed(() => ({
  width: `${shown.value.w / frameRatio.value * 100}%`,
  height: `${shown.value.h * 100}%`,
  left: `${(frameRatio.value / 2 - centre.value.x * shown.value.w) / frameRatio.value * 100}%`,
  top: `${(0.5 - centre.value.y * shown.value.h) * 100}%`
}))

let dragFrom: { x: number, y: number } | null = null

function onPointerDown(e: PointerEvent) {
  dragFrom = { x: e.clientX, y: e.clientY }
  ;(e.currentTarget as HTMLElement).setPointerCapture(e.pointerId)
}

function onPointerMove(e: PointerEvent) {
  if (!dragFrom || !stage.value) return
  // Pixels dragged -> frame units -> fraction of the picture.
  const dx = (e.clientX - dragFrom.x) / stage.value.clientWidth * frameRatio.value
  const dy = (e.clientY - dragFrom.y) / stage.value.clientHeight
  dragFrom = { x: e.clientX, y: e.clientY }
  centre.value = { x: centre.value.x - dx / shown.value.w, y: centre.value.y - dy / shown.value.h }
  settle()
}

function onPointerUp() {
  dragFrom = null
}

function onWheel(e: WheelEvent) {
  zoom.value = Math.min(MAX_ZOOM, Math.max(1, zoom.value - Math.sign(e.deltaY) * 0.1))
}

const STEP = 0.02
function onKey(e: KeyboardEvent) {
  const move: Record<string, [number, number]> = {
    ArrowLeft: [-STEP, 0], ArrowRight: [STEP, 0], ArrowUp: [0, -STEP], ArrowDown: [0, STEP]
  }
  const by = move[e.key]
  if (!by) return
  e.preventDefault()
  centre.value = { x: centre.value.x + by[0], y: centre.value.y + by[1] }
  settle()
}

async function confirm() {
  if (!natural.value || !img.value || saving.value) return
  saving.value = true

  // The part of the original, in its own pixels, that the frame is showing.
  const sw = natural.value.w * frameRatio.value / shown.value.w
  const sh = natural.value.h / shown.value.h
  const sx = centre.value.x * natural.value.w - sw / 2
  const sy = centre.value.y * natural.value.h - sh / 2

  const scale = Math.min(1, MAX_OUTPUT_PX / Math.max(sw, sh))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(sw * scale)
  canvas.height = Math.round(sh * scale)
  const ctx = canvas.getContext('2d')!
  // JPEG has no transparency; without this a see-through PNG would save as black.
  ctx.fillStyle = '#fff'
  ctx.fillRect(0, 0, canvas.width, canvas.height)
  ctx.drawImage(img.value, sx, sy, sw, sh, 0, 0, canvas.width, canvas.height)

  const blob = await new Promise<Blob | null>(resolve => canvas.toBlob(resolve, 'image/jpeg', 0.9))
  saving.value = false
  if (!blob) {
    failed.value = true
    return
  }
  emit('confirm', new File([blob], 'cover.jpg', { type: 'image/jpeg' }))
}
</script>

<template>
  <div class="overlay show">
    <div class="modal crop-modal" role="dialog" aria-label="เลือกสัดส่วนรูป">
      <h3>เลือกสัดส่วนรูป</h3>
      <div class="sub">ลากรูปเพื่อเลื่อนตำแหน่ง · ใช้แถบด้านล่างเพื่อซูม</div>

      <div v-if="failed" class="err show">เปิดรูปนี้ไม่ได้ กรุณาเลือกไฟล์อื่น</div>

      <div class="crop-ratios" role="radiogroup" aria-label="สัดส่วน">
        <button
          v-for="r in RATIOS"
          :key="r.key"
          type="button"
          role="radio"
          :aria-checked="r.key === ratioKey"
          :class="{ active: r.key === ratioKey }"
          @click="ratioKey = r.key"
        >
          {{ r.label }}
        </button>
      </div>

      <div class="crop-stage-wrap">
        <div
          ref="stage"
          class="crop-stage"
          tabindex="0"
          aria-label="ลากหรือกดปุ่มลูกศรเพื่อเลื่อนรูป"
          :style="{ aspectRatio: String(frameRatio), width: `min(100%, calc(46dvh * ${frameRatio}))` }"
          @pointerdown="onPointerDown"
          @pointermove="onPointerMove"
          @pointerup="onPointerUp"
          @pointercancel="onPointerUp"
          @wheel.prevent="onWheel"
          @keydown="onKey"
        >
          <img
            ref="img"
            :src="url"
            alt=""
            draggable="false"
            :style="pictureStyle"
            @load="onLoad"
            @error="failed = true"
          >
        </div>
      </div>

      <div class="field crop-zoom">
        <label for="crop-zoom">ซูม</label>
        <input id="crop-zoom" v-model.number="zoom" type="range" min="1" :max="MAX_ZOOM" step="0.01">
      </div>

      <div class="modal-actions">
        <button class="btn btn-ghost" type="button" :disabled="saving" @click="emit('cancel')">ยกเลิก</button>
        <button class="btn btn-primary" type="button" :disabled="saving || !natural" @click="confirm">
          {{ saving ? 'กำลังเตรียมรูป...' : 'ใช้รูปนี้' }}
        </button>
      </div>
    </div>
  </div>
</template>
