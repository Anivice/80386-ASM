#!/usr/bin/env bash

gdb -ix gdb_init_real_mode.gdb -ex 'set tdesc filename target.xml' -ex 'target remote localhost:1234' -ex 'break *0x7c00'

