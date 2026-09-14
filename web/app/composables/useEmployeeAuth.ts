import { ref } from 'vue'

/** Mirrors public.employee. */
export interface Employee {
  id: string
  firstName: string
  lastName: string
  email: string
}

interface EmployeeRow {
  employee_id: string
  first_name: string
  last_name: string
  email: string
}

// Module-level so every page and the route middleware share one session view.
const employee = ref<Employee | null>(null)
let loaded: Promise<void> | null = null

/**
 * Email + password login for the employee section only; customers never sign in.
 * A valid Supabase account is not enough on its own — its email must also appear
 * in public.employee, otherwise the session is signed straight back out.
 */
export function useEmployeeAuth() {
  const supabase = useSupabaseClient()

  async function refresh() {
    const { data } = await supabase.auth.getSession()
    const email = data.session?.user.email?.toLowerCase()
    if (!email) {
      employee.value = null
      return
    }

    // RLS only returns the caller's own employee row; the client-side match keeps
    // this correct even before rls.sql has been applied.
    const { data: employeeData } = await supabase.from('employee').select('employee_id, first_name, last_name, email')
    const rows = (employeeData ?? []) as EmployeeRow[]
    const row = rows.find(r => r.email.toLowerCase() === email)
    employee.value = row
      ? { id: row.employee_id, firstName: row.first_name, lastName: row.last_name, email: row.email }
      : null
  }

  function ensureLoaded() {
    if (!loaded) loaded = refresh()
    return loaded
  }

  async function signIn(email: string, password: string): Promise<string | null> {
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
    if (error) {
      if (error.code === 'invalid_credentials') return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'
      if (error.code === 'email_not_confirmed') return 'บัญชีนี้ยังไม่ได้ยืนยันอีเมล กรุณาติดต่อผู้ดูแลระบบ'
      return `เข้าสู่ระบบไม่สำเร็จ: ${error.message}`
    }

    await refresh()
    if (!employee.value) {
      await supabase.auth.signOut()
      return 'บัญชีนี้ไม่มีสิทธิ์เข้าใช้งานส่วนเจ้าหน้าที่'
    }
    return null
  }

  async function signOut() {
    await supabase.auth.signOut()
    employee.value = null
  }

  return { employee, ensureLoaded, signIn, signOut }
}
