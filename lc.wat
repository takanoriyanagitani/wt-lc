(module

  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (import "wasi_snapshot_preview1" "fd_read"
    (func $fd_read (param i32 i32 i32 i32) (result i32)))

  (global $STDIN i32 (i32.const 0))
  (global $STDOUT i32 (i32.const 1))
  (global $STDERR i32 (i32.const 2))

  (global $HALF_PAGE i32 (i32.const 32768))
  (global $FULL_PAGE i32 (i32.const 65536))

  (global $FD_WRIT_IOVEC_PTR i32 (i32.const 0x0001_0000))
  (global $FD_WRIT_IOBUF_PTR i32 (i32.const 0x0002_0000))
  (global $FD_WRIT_BWRIT_PTR i32 (i32.const 0x0003_0000))

  (global $FD_READ_IOVEC_PTR i32 (i32.const 0x0004_0000))
  (global $FD_READ_IOBUF_PTR i32 (i32.const 0x0005_0000))
  (global $FD_READ_BREAD_PTR i32 (i32.const 0x0006_0000))

  (memory (export "memory") 7)

  (func $buf2lc1page
    (param $bufptr i32)
    (result i32)

    (local $ptr i32)
    (local $end i32)
    (local $cnt i32)

    local.get $bufptr
    local.set $ptr

    local.get $bufptr
    global.get $FULL_PAGE
    i32.add
    local.set $end

    loop
      local.get $end
      local.get $ptr
      i32.le_u
      if
        local.get $cnt
        return
      end

      ;; process 4x v128
      ;;;; 1st
      local.get $ptr
      v128.load offset=0
      v128.const i64x2 0x0a0a_0a0a_0a0a_0a0a 0x0a0a_0a0a_0a0a_0a0a
      i8x16.eq
      i8x16.bitmask
      i32.popcnt
      ;;;; 2nd
      local.get $ptr
      v128.load offset=16
      v128.const i64x2 0x0a0a_0a0a_0a0a_0a0a 0x0a0a_0a0a_0a0a_0a0a
      i8x16.eq
      i8x16.bitmask
      i32.popcnt
      ;;;; 3rd
      local.get $ptr
      v128.load offset=32
      v128.const i64x2 0x0a0a_0a0a_0a0a_0a0a 0x0a0a_0a0a_0a0a_0a0a
      i8x16.eq
      i8x16.bitmask
      i32.popcnt
      ;;;; 4th
      local.get $ptr
      v128.load offset=48
      v128.const i64x2 0x0a0a_0a0a_0a0a_0a0a 0x0a0a_0a0a_0a0a_0a0a
      i8x16.eq
      i8x16.bitmask
      i32.popcnt

      i32.add
      i32.add
      i32.add

      local.get $cnt
      i32.add
      local.set $cnt

      local.get $ptr
      i32.const 64
      i32.add
      local.set $ptr

      br 0
    end

    local.get $cnt
  )

  (func $i64le2stdout
    (param $i i64)
    (result i64)

    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 8 ;; 64-bit integer = 8 bytes
    i32.store offset=4

    ;; copy the val
    global.get $FD_WRIT_IOBUF_PTR
    local.get $i
    i64.store

    ;; print to stdout
    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 8
    i32.ne
    if
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $main (export "_start")
    (local $read_rslt i32)
    (local $read_size i32)

    (local $tot i64)

    ;; setup the read iovec
    global.get $FD_READ_IOVEC_PTR
    global.get $FD_READ_IOBUF_PTR
    i32.store
    global.get $FD_READ_IOVEC_PTR
    global.get $FULL_PAGE
    i32.store offset=4

    loop
      ;; clear the buffer
      global.get $FD_READ_IOBUF_PTR
      i32.const 0
      global.get $FULL_PAGE
      memory.fill

      global.get $STDIN
      global.get $FD_READ_IOVEC_PTR
      i32.const 1 ;; single buffer
      global.get $FD_READ_BREAD_PTR
      call $fd_read
      local.set $read_rslt
      global.get $FD_READ_BREAD_PTR
      i32.load
      local.set $read_size
      local.get $read_rslt
      i32.const 0
      i32.ne
      if
        i32.const 1
        call $proc_exit
        return
      end

      local.get $read_size
      i32.const 0
      i32.eq
      if
        local.get $tot
        call $i64le2stdout
        i64.const 0
        i64.ne
        if
          i32.const 1
          call $proc_exit
        end

        i32.const 0
        call $proc_exit
        return
      end

      ;; count '0x0a'
      global.get $FD_READ_IOBUF_PTR
      call $buf2lc1page
      i64.extend_i32_u
      local.get $tot
      i64.add
      local.set $tot

      br 0
    end
  )

)
