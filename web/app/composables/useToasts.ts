import { reactive } from 'vue'

export interface Toast {
  id: number
  message: string
  isError: boolean
}

const toasts = reactive<Toast[]>([])
let seq = 1

export function useToasts() {
  function addToast(message: string, isError = false) {
    const id = seq++
    toasts.push({ id, message, isError })
    setTimeout(() => {
      const idx = toasts.findIndex(t => t.id === id)
      if (idx !== -1) toasts.splice(idx, 1)
    }, 3200)
  }

  return { toasts, addToast }
}
