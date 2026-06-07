#!/bin/bash

wsm="./opt.wasm"
wsm="./lc.wasm"

wikix=~/Downloads/enwiki-20250801-pages-articles-multistream-index.txt

i64le2human() {
	imports='import struct; import sys; import functools; import operator;'

	cat /dev/stdin |
		python3 -c "${imports}"'functools.reduce(
    lambda state, f: f(state),
    [
      struct.Struct("<q").unpack,
      operator.itemgetter(0),
      print,
    ],
    sys.stdin.buffer.read(8),
  )'
}

lines_count() {
	cat /dev/stdin |
		wazero run "${wsm}"
}

testdata_heavy() {
	dd if=/dev/zero bs=1048576 count=16384 status=none |
		cat - <(printf 'helo\n')
}

bench_wazero() {
	time testdata_heavy |
		lines_count |
		i64le2human
}

bench_wc() {
	time testdata_heavy |
		wc -l
}

bench_w0_wikix() {
	time cat "${wikix}" |
		lines_count |
		i64le2human
}

bench_wc_wikix() {
	time cat "${wikix}" |
		wc -l
}

bench_dd() {
	echo bench using wazero
	bench_wazero
	echo

	echo bench using wc
	bench_wc
}

bench_wikix() {
	echo bench using wazero
	bench_w0_wikix
	echo

	echo bench using wc
	bench_wc_wikix
}

bench_dd
#bench_wikix
