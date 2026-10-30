#!/usr/bin/env bash
# break-even.sh — chapter 9 (ch09:45-61), the cost calculator, with your numbers.
#
#   ./break-even.sh --cloud <$/month> --electricity <$/month> --hardware <$> [--months <n>]
#
# --cloud        what you paid for cloud coding last month (average a few statements)
# --electricity  your estimate for running models locally for a month
# --hardware     what you bought for this; 0 if you run on a machine you already own
# --months       optional: how long you'll use that hardware, to show it spread per month
#
# payback = hardware / (cloud - electricity). the print's steps 4 and 5 subtract the
# hardware twice; BOOK-FIXES.md has the arithmetic.
set -eu

usage() {
  echo "usage: ./break-even.sh --cloud <\$/month> --electricity <\$/month> --hardware <\$> [--months <n>]"
  echo "every number is yours: hardware is 0 if you bought nothing for this."
}
die() { echo "break-even.sh: $*" >&2; usage >&2; exit 1; }

num() {
  case "$2" in
    ''|.|*[!0-9.]*|*.*.*) die "$1 needs a number in dollars, like 60 or 4.50 (got '$2')" ;;
  esac
}

cloud="" elec="" hw="" months=""
while [ $# -gt 0 ]; do
  case "$1" in
    --cloud) [ $# -ge 2 ] || die "--cloud needs a value"; cloud=$2; shift 2 ;;
    --electricity) [ $# -ge 2 ] || die "--electricity needs a value"; elec=$2; shift 2 ;;
    --hardware) [ $# -ge 2 ] || die "--hardware needs a value"; hw=$2; shift 2 ;;
    --months) [ $# -ge 2 ] || die "--months needs a value"; months=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument '$1'" ;;
  esac
done
[ -n "$cloud" ] || die "--cloud is required"
[ -n "$elec" ] || die "--electricity is required"
[ -n "$hw" ] || die "--hardware is required (0 if you bought nothing)"
num --cloud "$cloud"; num --electricity "$elec"; num --hardware "$hw"
if [ -n "$months" ]; then
  case "$months" in ''|*[!0-9]*|0) die "--months needs a whole number above 0 (got '$months')" ;; esac
fi

awk -v c="$cloud" -v e="$elec" -v h="$hw" -v m="$months" '
function money(x) { return (x < 0 ? "-$" : "$") sprintf("%.2f", (x < 0 ? -x : x)) }
BEGIN {
  s = c - e
  printf "monthly cloud cost:  %s\n", money(c)
  printf "monthly local cost:  %s electricity\n", money(e)
  if (m != "" && h > 0)
    printf "                     %s with the %s hardware spread over %d months\n", money(e + h / m), money(h), m
  printf "saved each month:    %s (cloud minus electricity)\n", money(s)
  if (s <= 0)
    printf "break-even:          never on cost alone: electricity is %s cloud\n", (s == 0 ? "equal to" : "more than")
  else if (h == 0)
    printf "break-even:          immediate: no hardware to pay back\n"
  else {
    b = h / s; n = int(b); if (n < b) n++
    printf "break-even:          %.1f months (%s / %s): ahead from month %d\n", b, money(h), money(s), n
  }
  y = s * 12 - h
  printf "first-year net:      %s%s (%s x 12 - %s)\n", (y > 0 ? "+" : ""), money(y), money(s), money(h)
}'
