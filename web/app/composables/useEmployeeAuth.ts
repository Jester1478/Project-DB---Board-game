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
 * The route middleware waits for the sign-in check before anything is drawn, so a
 * check that never answers would leave the employee section a blank page for good.
 */
const CHECK_TIMEOUT_MS = 6000
/** The last check got no answer in time; the login page explains instead of looking broken. */
const checkTimedOut = ref(false)

function orTimeout<T>(work: PromiseLike<T>): Promise<T> {
  return Promise.race([
    work,
    new Promise<never>((_, reject) => setTimeout(() => reject(new Error('sign-in check timed out')), CHECK_TIMEOUT_MS))
  ])
}

/**
 * Email + password login for the employee section only; customers never sign in.
 * A valid Supabase account is not enough on its own — its email must also appear
 * in public.employee, otherwise the session is signed straight back out.
 */
export function useEmployeeAuth() {
  const supabase = useSupabaseClient()

  async function refresh() {
    const { data } = await orTimeout(supabase.auth.getSession())
    const email = data.session?.user.email?.toLowerCase()
    if (!email) {
      employee.value = null
      return
    }

    // RLS only returns the caller's own employee row; the client-side match keeps
    // this correct even before rls.sql has been applied.
    const { data: employeeData } = await orTimeout(supabase.from('employee').select('employee_id, first_name, last_name, email'))
    const rows = (employeeData ?? []) as EmployeeRow[]
    const row = rows.find(r => r.email.toLowerCase() === email)
    employee.value = row
      ? { id: row.employee_id, firstName: row.first_name, lastName: row.last_name, email: row.email }
      : null
  }

  function ensureLoaded() {
    if (!loaded) {
      loaded = refresh()
        .then(() => { checkTimedOut.value = false })
        .catch(e => {
          console.error('[auth] sign-in check failed', e)
          employee.value = null
          checkTimedOut.value = true
          loaded = null  // not remembered, so the next page tries again
        })
    }
    return loaded
  }

  async function signIn(email: string, password: string): Promise<string | null> {
    const { error } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
    if (error) {
      if (error.code === 'invalid_credentials') return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'
      if (error.code === 'email_not_confirmed') return 'บัญชีนี้ยังไม่ได้ยืนยันอีเมล กรุณาติดต่อผู้ดูแลระบบ'
      if (error.code === 'over_request_rate_limit') return 'ลองเข้าสู่ระบบถี่เกินไป กรุณารอสักครู่แล้วลองใหม่'
      // The raw message is English; keep it in the console rather than on screen.
      console.error('[auth] sign-in failed', error)
      return 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบอีเมลและรหัสผ่าน แล้วลองใหม่อีกครั้ง'
    }

    try {
      await refresh()
      checkTimedOut.value = false
    } catch (e) {
      console.error('[auth] sign-in check failed', e)
      return 'เชื่อมต่อฐานข้อมูลไม่ได้ในขณะนี้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง'
    }
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

  return { employee, checkTimedOut, ensureLoaded, signIn, signOut }
}
