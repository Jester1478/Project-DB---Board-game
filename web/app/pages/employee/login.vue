<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useEmployeeAuth } from '~/composables/useEmployeeAuth'

definePageMeta({ layout: 'employee' })

const { employee, ensureLoaded, signIn } = useEmployeeAuth()

const email = ref('')
const password = ref('')
const errorMessage = ref('')
const busy = ref(false)

onMounted(async () => {
  await ensureLoaded()
  // replace, not push: otherwise Back from the dashboard lands here and is
  // bounced straight forward again, which reads as a broken Back button.
  if (employee.value) await navigateTo('/employee', { replace: true })
})

async function submit() {
  if (busy.value) return
  errorMessage.value = ''
  busy.value = true
  const error = await signIn(email.value, password.value)
  busy.value = false

  if (error) {
    errorMessage.value = error
    return
  }
  // Drops the login page from history, so Back returns to wherever they came from.
  await navigateTo('/employee', { replace: true })
}
</script>

<template>
  <main class="login-page">
    <form class="login-card" @submit.prevent="submit">
      <h2>เข้าสู่ระบบเจ้าหน้าที่</h2>
      <p class="sub">ใช้อีเมลและรหัสผ่านที่ได้รับจากผู้ดูแลระบบ</p>
      <div v-if="errorMessage" class="err">{{ errorMessage }}</div>
      <div class="field">
        <label>อีเมล</label>
        <input v-model="email" type="email" autocomplete="username" required>
      </div>
      <div class="field">
        <label>รหัสผ่าน</label>
        <input v-model="password" type="password" autocomplete="current-password" required>
      </div>
      <button class="btn btn-primary" type="submit" :disabled="busy">
        {{ busy ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ' }}
      </button>
    </form>
  </main>
</template>
