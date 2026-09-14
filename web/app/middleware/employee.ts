import { useEmployeeAuth } from '~/composables/useEmployeeAuth'

export default defineNuxtRouteMiddleware(async () => {
  const { ensureLoaded, employee } = useEmployeeAuth()
  await ensureLoaded()
  if (!employee.value) return navigateTo('/employee/login')
})
