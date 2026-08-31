import { reactive, ref } from 'vue'

// Matches the Status CHECK constraint on the BOOKING table in supabase/schema.sql
export type BookingStatus = 'Reserved' | 'In_Use' | 'Overdue' | 'Returned' | 'Cancelled'

export interface Copy {
  id: string
  label: string
}

export interface Game {
  id: string
  name: string
  icon: string
  category: string
  minP: number
  maxP: number
  playtime: number
  copies: Copy[]
  howToPlay: string[]
}

export interface Booking {
  id: string
  gameId: string
  copyId: string
  studentId: string
  studentName: string
  start: Date
  end: Date
  status: BookingStatus
  actualReturn: Date | null
}

export interface BookingInput {
  studentId: string
  studentName: string
  gameId: string
  copyId: string
  start: Date
  end: Date
}

const games: Game[] = [
  { id: 'catan', name: 'Catan', icon: '🌾', category: 'Strategy', minP: 3, maxP: 4, playtime: 90,
    copies: [{ id: 'CATAN-01', label: 'CATAN-01' }, { id: 'CATAN-02', label: 'CATAN-02' }],
    howToPlay: [
      'ผลัดกันทอยลูกเต๋าเพื่อรับทรัพยากร (ไม้ อิฐ ขนแกะ ข้าวสาลี แร่) ตามช่องที่ทอยได้',
      'ใช้ทรัพยากรแลกเปลี่ยนกับผู้เล่นคนอื่นหรือกับธนาคาร',
      'สร้างถนน หมู่บ้าน และเมือง เพื่อสะสมแต้ม',
      'ผู้เล่นคนแรกที่ทำได้ 10 แต้มชัยชนะเป็นผู้ชนะ'
    ] },
  { id: 'codenames', name: 'Codenames', icon: '🕵️', category: 'Party', minP: 4, maxP: 8, playtime: 20,
    copies: [{ id: 'CODE-01', label: 'CODE-01' }],
    howToPlay: [
      'แบ่งผู้เล่นเป็น 2 ทีม แต่ละทีมมีหัวหน้าสายลับ 1 คน',
      'หัวหน้าสายลับให้คำใบ้เป็นคำเดียวพร้อมตัวเลข เพื่อให้ทีมทายคำของทีมตัวเองบนกระดาน',
      'ระวังอย่าทายโดนคำของทีมตรงข้ามหรือคำมือสังหาร (Assassin) ไม่งั้นแพ้ทันที',
      'ทีมที่ทายคำของตัวเองครบก่อนเป็นฝ่ายชนะ'
    ] },
  { id: 'splendor', name: 'Splendor', icon: '💎', category: 'Strategy', minP: 2, maxP: 4, playtime: 30,
    copies: [{ id: 'SPLEN-01', label: 'SPLEN-01' }, { id: 'SPLEN-02', label: 'SPLEN-02' }],
    howToPlay: [
      'แต่ละตาเลือกทำอย่างใดอย่างหนึ่ง: เก็บโทเคนอัญมณี, จองการ์ดพัฒนา, หรือซื้อการ์ดพัฒนา',
      'ใช้โทเคนและโบนัสจากการ์ดที่ซื้อแล้วเพื่อซื้อการ์ดใบใหม่ที่แพงขึ้น',
      'การ์ดบางใบให้แต้มเกียรติยศ (Prestige Points) เมื่อซื้อ',
      'ผู้เล่นคนแรกที่มีแต้มเกียรติยศครบ 15 แต้มเป็นผู้ชนะ'
    ] },
  { id: 'coup', name: 'Coup', icon: '🎭', category: 'Party', minP: 2, maxP: 6, playtime: 15,
    copies: [{ id: 'COUP-01', label: 'COUP-01' }],
    howToPlay: [
      'ผู้เล่นแต่ละคนถือการ์ดตัวละครลับ 2 ใบ ที่ให้ความสามารถพิเศษต่างกัน',
      'ในแต่ละตา เลือกทำแอ็กชันตามการ์ด เช่น เก็บเงิน ลอบสังหาร หรือรัฐประหาร',
      'ผู้เล่นคนอื่นสามารถท้าทาย (Challenge) ได้ว่าคุณโกหกเรื่องการ์ดที่ถืออยู่หรือไม่',
      'ผู้เล่นคนสุดท้ายที่ยังมีอิทธิพล (การ์ด) เหลืออยู่เป็นผู้ชนะ'
    ] },
  { id: 'ticket', name: 'Ticket to Ride', icon: '🚂', category: 'Family', minP: 2, maxP: 5, playtime: 60,
    copies: [{ id: 'TTR-01', label: 'TTR-01' }],
    howToPlay: [
      'เก็บการ์ดรถไฟให้ครบสีและจำนวนตามเส้นทางที่ต้องการยึดครองบนแผนที่',
      'วางรถไฟของตัวเองลงบนเส้นทางเพื่อยึดครองและได้แต้ม',
      'ทำภารกิจ Destination Ticket ให้สำเร็จเพื่อรับแต้มเพิ่ม (ถ้าทำไม่สำเร็จจะถูกหักแต้ม)',
      'เกมจบเมื่อมีผู้เล่นเหลือรถไฟน้อยกว่า 3 ตัว แล้วนับแต้มรวมหาผู้ชนะ'
    ] },
  { id: 'sushi', name: 'Sushi Go!', icon: '🍣', category: 'Family', minP: 2, maxP: 5, playtime: 20,
    copies: [{ id: 'SUSHI-01', label: 'SUSHI-01' }, { id: 'SUSHI-02', label: 'SUSHI-02' }],
    howToPlay: [
      'ผู้เล่นแต่ละคนได้รับมือการ์ดเท่ากัน เลือกเก็บ 1 ใบแล้วส่งมือที่เหลือให้คนถัดไป',
      'ทำเช่นนี้ต่อไปเรื่อย ๆ จนหมดมือการ์ดในแต่ละรอบ',
      'การ์ดแต่ละชนิดให้แต้มต่างกันตามชุดที่สะสมได้ (เช่น มากิที่สุด, ชุดซาชิมิครบ 3 ใบ)',
      'เล่นครบ 3 รอบแล้วรวมแต้มทั้งหมด ผู้ที่แต้มสูงสุดเป็นผู้ชนะ'
    ] }
]

let bookingSeq = 1
function nextBookingId() {
  return 'BK-' + String(bookingSeq++).padStart(3, '0')
}

function overlaps(aStart: Date, aEnd: Date, bStart: Date, bEnd: Date) {
  return aStart < bEnd && bStart < aEnd
}

let store: ReturnType<typeof createStore> | null = null

function createStore() {
  const simNow = ref(new Date())
  const bookings = reactive<Booking[]>([])

  function todayAt(h: number, m: number) {
    const d = new Date(simNow.value)
    d.setHours(h, m, 0, 0)
    return d
  }

  function seedData() {
    const push = (gameId: string, copyId: string, sId: string, sName: string,
      sh: number, sm: number, eh: number, em: number, status: BookingStatus) => {
      bookings.push({
        id: nextBookingId(),
        gameId, copyId, studentId: sId, studentName: sName,
        start: todayAt(sh, sm), end: todayAt(eh, em),
        status, actualReturn: null
      })
    }
    const nowH = simNow.value.getHours()
    push('catan', 'CATAN-01', '68023111', 'สมชาย ใจดี', Math.max(0, nowH - 2), 0, nowH, 0, 'In_Use')
    push('catan', 'CATAN-02', '68023222', 'พิมพ์ชนก แซ่ตั้ง', nowH + 1, 15, nowH + 3, 15, 'Reserved')
    push('splendor', 'SPLEN-01', '68023333', 'ธนกร ศรีสุข', nowH + 2, 0, nowH + 2, 45, 'Reserved')
    push('sushi', 'SUSHI-01', '68023444', 'กมลชนก ทองดี', Math.max(0, nowH - 1), 0, nowH + 0, 30, 'In_Use')
    push('codenames', 'CODE-01', '68023555', 'ภูผา เอกจิตร', nowH + 4, 0, nowH + 5, 0, 'Reserved')
  }

  function activeBookingsForStudent(studentId: string) {
    return bookings.filter(b => b.studentId === studentId && (b.status === 'Reserved' || b.status === 'In_Use'))
  }

  function hasOverdue(studentId: string) {
    return bookings.some(b => b.studentId === studentId && b.status === 'Overdue')
  }

  function validateBooking({ studentId, studentName, gameId, copyId, start, end }: BookingInput): string | null {
    if (!studentId || !studentName) return 'กรุณากรอกรหัสนิสิตและชื่อ-นามสกุล'
    if (!(start instanceof Date) || !(end instanceof Date) || isNaN(+start) || isNaN(+end)) return 'กรุณาระบุช่วงเวลาให้ถูกต้อง'
    if (end <= start) return 'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม'
    const mins = (end.getTime() - start.getTime()) / 60000
    if (mins < 30) return 'ระยะเวลาการจองต้องอย่างน้อย 30 นาที (BR-02)'
    if (mins > 240) return 'ระยะเวลาการจองต้องไม่เกิน 4 ชั่วโมง (BR-02)'
    if (hasOverdue(studentId)) return 'คุณมีรายการค้างสถานะ OVERDUE โปรดคืนเกมก่อนจองใหม่ (BR-04)'
    if (activeBookingsForStudent(studentId).length >= 2) return 'คุณมีรายการจองที่ใช้งาน/รอใช้งานอยู่แล้ว 2 รายการ (BR-01)'
    const conflict = bookings.some(b => b.copyId === copyId
      && (b.status === 'Reserved' || b.status === 'In_Use' || b.status === 'Overdue')
      && overlaps(start, end, b.start, b.end))
    if (conflict) return 'ช่วงเวลานี้ถูกจองเต็มแล้ว (BR-03)'
    return null
  }

  function recomputeOverdue() {
    bookings.forEach(b => {
      if (b.status === 'In_Use' && simNow.value > b.end) b.status = 'Overdue'
    })
  }

  function copyStatus(copy: Copy): 'free' | 'busy' {
    const blocking = bookings.some(b => b.copyId === copy.id && (b.status === 'In_Use' || b.status === 'Overdue'))
    return blocking ? 'busy' : 'free'
  }

  function getGame(gameId: string) {
    return games.find(g => g.id === gameId)
  }

  function freeCopyCount(game: Game) {
    return game.copies.filter(c => copyStatus(c) === 'free').length
  }

  function bookingsForCopy(copyId: string) {
    return bookings
      .filter(b => b.copyId === copyId && b.status !== 'Returned' && b.status !== 'Cancelled')
      .sort((a, b) => +a.start - +b.start)
  }

  function addBooking(input: BookingInput) {
    const error = validateBooking(input)
    if (error) return { error }
    bookings.push({
      id: nextBookingId(),
      gameId: input.gameId,
      copyId: input.copyId,
      studentId: input.studentId,
      studentName: input.studentName,
      start: input.start,
      end: input.end,
      status: 'Reserved',
      actualReturn: null
    })
    return { error: null }
  }

  function markInUse(id: string) {
    const b = bookings.find(x => x.id === id)
    if (b) b.status = 'In_Use'
    return b
  }

  function markReturned(id: string) {
    const b = bookings.find(x => x.id === id)
    if (b) {
      b.status = 'Returned'
      b.actualReturn = new Date(simNow.value)
    }
    return b
  }

  function setSimNow(d: Date) {
    simNow.value = d
    recomputeOverdue()
  }

  function tick(minutes = 1) {
    simNow.value = new Date(simNow.value.getTime() + minutes * 60000)
    recomputeOverdue()
  }

  seedData()

  return {
    games,
    bookings,
    simNow,
    todayAt,
    copyStatus,
    getGame,
    freeCopyCount,
    bookingsForCopy,
    addBooking,
    markInUse,
    markReturned,
    setSimNow,
    tick,
    recomputeOverdue
  }
}

export function useBoardGameStore() {
  if (!store) store = createStore()
  return store
}
