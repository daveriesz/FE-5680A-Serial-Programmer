#!/bin/bash

# MIT License

# Copyright (c) 2023 David Riesz

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

serialdev=

status=
ref=
freq=

doraw=0

sendrecv()
{
  tempfile=$( mktemp -t fesh.XXXXXXXXXX )
  exec 3<>$serialdev
  stty -F $serialdev 9600 cs8 -cstopb -parenb #-ocrnl raw -echo
  
  cat <&3 >"$tempfile" &
  catpid=$!
  printf "%s\r" "$@" >&3
  if [ $doraw -ne 0 ] ; then printf "wrote to serial:\n>>%s<<\n" "$@" >&2 ; fi
  cont=1
  while [ $cont -ne 0 ] ; do
    sleep .1s
    ok=$(cat "$tempfile" | tr "\015" "\n" | tail -1)
    if [ "$ok" = "OK" ] ; then cont=0 ; fi
  done

  kill $catpid
  wait $catpid 2>/dev/null
  exec 3<&-
  exec 3>&-

  data=$(cat "$tempfile" | tr "\015" "\n")
  if [ $doraw -ne 0 ] ; then printf "read from serial:\n>>%s<<\n" "$data" >&2 ; fi
  printf "%s\n" "$data"

  rm "$tempfile"
}

getstatus()
{
  status=$(sendrecv "S")
  rr=$(echo "$status" | egrep "^R=" | sed 's/^R=\([0-9\.]*\)Hz F=\(........\)\(........\)$/\1/g')
  f1=$(echo "$status" | egrep "^R=" | sed 's/^R=\([0-9\.]*\)Hz F=\(........\)\(........\)$/\2/g')
  f2=$(echo "$status" | egrep "^R=" | sed 's/^R=\([0-9\.]*\)Hz F=\(........\)\(........\)$/\3/g')
  ref="$rr"
  freq=$(echo 3k 10o 16i $f1.$f2 Ai $rr \* 2 32^ / pq | dc -)
}

getfreq()
{
  getstatus
  printf "Frequency: %'.2f Hz\n" "$freq"
}

setfreq()
{
  if ! echo "$1" | egrep "^([0-9]+|[0-9]+\.[0-9]+)$" >/dev/null ; then
    echo "Invalid frequency: $1" >&2
    echo "Frequency must be a whole number.\n" >&2
    exit 1
  fi
  getstatus

  val1=$(echo 20k 10i 16o "$1" 2 32 ^ \* $ref / pq | dc - | sed 's/^\([0-9A-F]*\)\.\(........\).*$/\1/g')
  val2=$(echo 20k 10i 16o "$1" 2 32 ^ \* $ref / pq | dc - | sed 's/^\([0-9A-F]*\)\.\(........\).*$/\2/g')
  val=$(printf "%.8x%.8x" "0x$val1" "0x$val2")
  data=$(sendrecv "F=$val")
  if [ "$data" = OK ] ; then
    echo "Set frequency command succeeded."
  else
    echo "Set frequency command failed." >&2
  fi
}

write()
{
  data=$(sendrecv "E")
  if [ "$data" = OK ] ; then
    echo "Write frequency command succeeded."
  else
    echo "Write frequency command failed." >&2
  fi
}

dohelp()
{
  (
    bn=$(basename "$0")
    printf "Usage:\n"
    printf "\n"
    printf "  $bn help\n"
    printf "  $bn --help\n"
    printf "  $bn -help\n"
    printf "    Print this help message\n"
    printf "\n"
    printf "  $bn device <dev> [opt] <cmd ...>\n"
    printf "    Execute command(s) on a given FE56xx serial device, where:\n"
    printf "      \"device <dev>\" specifies the serial device\n"
    printf "      [opt] is an optional argument:\n"
    printf "         \"raw\"  print serial I/O from the device to stderr\n"
    printf "      <cmd> is one or more of the following:\n"
    printf "        \"get\"   print the current frequency\n"
    printf "        \"set N\" set the frequency to N Hz\n"
    printf "        \"write\" write the current frequency to NVRAM\n"
    printf "\n"
  ) >&2
  exit 1
}

commands=( )

while [ $# -gt 0 ] ; do
  case "$1" in
    device) shift ; serialdev="$1"                         ;;
    get)            commands[${#commands[@]}]="getfreq"    ;;
    set)    shift ; commands[${#commands[@]}]="setfreq $1" ;;
    write)          commands[${#commands[@]}]="write"      ;;
    raw)            doraw=1                                ;;
    -h|--help|help) dohelp                                 ;;
    *) echo "Unrecognized argument: $1" >&2 ; exit 1 ;;
  esac
  shift
done

if [ "$serialdev" = "" ] ; then
  echo "No serial device specified." >&2
  exit 1
elif ! stty -F "$serialdev" >/dev/null 2>/dev/null ; then
  echo "Cannot open serial device: $serialdev" >&2
  exit 1
fi

for (( ii=0 ; ii<${#commands[@]} ; ii++ ))
{
  ${commands[$ii]}
}

