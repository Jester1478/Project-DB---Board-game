<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Game } from '~/composables/useBoardGameStore'

const props = defineProps<{ game: Game }>()

const { freeCopyCount } = useBoardGameStore()
const router = useRouter()

const free = computed(() => freeCopyCount(props.game))
const total = computed(() => props.game.copies.length)

function goToDetail() {
  router.push(`/games/${props.game.id}`)
}
</script>

<template>
  <div class="card-game" role="button" tabindex="0" @click="goToDetail" @keyup.enter="goToDetail">
    <div class="card-game-icon">{{ game.icon }}</div>
    <span class="cat">{{ game.category }}</span>
    <h3>{{ game.name }}</h3>
    <div class="meta">{{ game.minP }}-{{ game.maxP }} ผู้เล่น · ~{{ game.playtime }} นาที</div>
    <div class="status-pill" :class="free > 0 ? 'avail' : 'full'">
      <span class="dot" />
      {{ free > 0 ? `เหลือ ${free}/${total} กล่อง` : `ไม่ว่าง (0/${total} กล่อง)` }}
    </div>
    <button class="btn btn-primary" @click.stop="goToDetail">จองเลย →</button>
  </div>
</template>
