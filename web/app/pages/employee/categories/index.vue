<script setup lang="ts">
import { nextTick, ref } from 'vue'
import { useBoardGameStore } from '~/composables/useBoardGameStore'
import type { Category } from '~/composables/useBoardGameStore'
import { useToasts } from '~/composables/useToasts'

definePageMeta({ layout: 'employee', middleware: 'employee' })

const { categories, loading, loadError, categoryGameCount, createCategory, renameCategory, deleteCategory } = useBoardGameStore()
const { addToast } = useToasts()

const newName = ref('')
const errorMessage = ref('')
const busy = ref(false)

const editingId = ref<string | null>(null)
const editName = ref('')
const editInput = ref<HTMLInputElement[]>([])

async function add() {
  if (busy.value) return
  errorMessage.value = ''
  busy.value = true
  const name = newName.value.trim()
  const { error } = await createCategory(name)
  busy.value = false
  if (error) {
    errorMessage.value = error
    return
  }
  newName.value = ''
  addToast(`เพิ่มหมวดหมู่ "${name}" แล้ว`, false)
}

async function startRename(category: Category) {
  editingId.value = category.id
  editName.value = category.name
  errorMessage.value = ''
  await nextTick()
  editInput.value[0]?.select()
}

function cancelRename() {
  editingId.value = null
  editName.value = ''
}

async function saveRename(category: Category) {
  if (busy.value) return
  busy.value = true
  const name = editName.value.trim()
  const { error } = await renameCategory(category.id, name)
  busy.value = false
  if (error) {
    addToast(error, true)
    return
  }
  if (name !== category.name) addToast(`เปลี่ยนชื่อ "${category.name}" เป็น "${name}" แล้ว`, false)
  cancelRename()
}

async function remove(category: Category) {
  if (busy.value) return
  const count = categoryGameCount(category.id)
  const effect = count
    ? `\nเกม ${count} เกมในหมวดนี้จะไม่ถูกลบ แค่ถูกเอาออกจากหมวดหมู่นี้`
    : ''
  if (!confirm(`ลบหมวดหมู่ "${category.name}"?${effect}`)) return

  busy.value = true
  const { error } = await deleteCategory(category.id)
  busy.value = false
  addToast(error ?? `ลบหมวดหมู่ "${category.name}" แล้ว`, !!error)
}
</script>

<template>
  <main>
    <div class="section-head">
      <h2>หมวดหมู่</h2>
      <p>กดชื่อหมวดหมู่เพื่อดูเกมในหมวดนั้น เพิ่มหรือเอาเกมออก และแก้ไขเกมจากในนั้นได้</p>
    </div>

    <form class="panel form-panel" @submit.prevent="add">
      <div v-if="errorMessage" class="err">{{ errorMessage }}</div>
      <div class="inline-form">
        <input v-model="newName" type="text" maxlength="100" placeholder="ชื่อหมวดหมู่ใหม่ เช่น Card Game" aria-label="ชื่อหมวดหมู่ใหม่">
        <button class="btn btn-primary btn-sm" type="submit" :disabled="busy || !newName.trim()">+ เพิ่มหมวดหมู่</button>
      </div>
    </form>

    <p v-if="loadError" class="err">{{ loadError }}</p>

    <table class="book-table">
      <thead>
        <tr><th>หมวดหมู่</th><th>จำนวนเกม</th><th /></tr>
      </thead>
      <tbody>
        <tr v-for="c in categories" :key="c.id">
          <td>
            <input
              v-if="editingId === c.id"
              ref="editInput"
              v-model="editName"
              class="cell-input"
              type="text"
              maxlength="100"
              aria-label="ชื่อหมวดหมู่"
              @keyup.enter="saveRename(c)"
              @keyup.esc="cancelRename"
            >
            <NuxtLink v-else :to="`/employee/categories/${c.id}`" class="name-link">{{ c.name }}</NuxtLink>
          </td>
          <td>{{ categoryGameCount(c.id) }} เกม</td>
          <td class="cell-right">
            <div v-if="editingId === c.id" class="cell-actions">
              <button class="btn btn-primary btn-sm" type="button" :disabled="busy || !editName.trim()" @click="saveRename(c)">บันทึก</button>
              <button class="btn btn-ghost btn-sm" type="button" :disabled="busy" @click="cancelRename">ยกเลิก</button>
            </div>
            <div v-else class="cell-actions">
              <NuxtLink :to="`/employee/categories/${c.id}`" class="btn btn-primary btn-sm">ดูเกม</NuxtLink>
              <button class="btn btn-ghost btn-sm" type="button" :disabled="busy || !!editingId" @click="startRename(c)">เปลี่ยนชื่อ</button>
              <button class="btn btn-ghost btn-sm" type="button" :disabled="busy || !!editingId" @click="remove(c)">ลบ</button>
            </div>
          </td>
        </tr>
        <tr v-if="!categories.length">
          <td colspan="3" class="empty-row">{{ loading ? 'กำลังโหลด...' : 'ยังไม่มีหมวดหมู่' }}</td>
        </tr>
      </tbody>
    </table>
  </main>
</template>
