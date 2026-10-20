#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$0")"

DOMAIN_MIN_LINES=50000
RULESET_COMPILER="./bin/ruleset-compiler"
OUT_DIR="./out"

# 数据源：默认主源 + 镜像回退；显式指定 MOD_BASE_URL 时仅用该源（便于故障注入）
if [ -n "${MOD_BASE_URL:-}" ]; then
	BASE_URLS=("$MOD_BASE_URL")
else
	BASE_URLS=(
		"https://raw.githubusercontent.com/Mujinniao/list/data"
		"https://ghfast.top/https://raw.githubusercontent.com/Mujinniao/list/data"
		"https://gh-proxy.com/https://raw.githubusercontent.com/Mujinniao/list/data"
	)
fi

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }
die() { log "FAIL: $*"; exit 1; }

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
start_ts=$(date +%s)

# 0. 预检
for cmd in curl jq awk sort grep head; do
	command -v "$cmd" >/dev/null 2>&1 || die "缺少依赖命令: $cmd"
done
if [ ! -f "$RULESET_COMPILER" ]; then
	log "缺少 $RULESET_COMPILER，从 data 分支获取"
	mkdir -p bin
	compiler_ok=0
	for cbase in \
		"https://raw.githubusercontent.com/ANOONIMASXP/MOD/data/bin" \
		"https://ghfast.top/https://raw.githubusercontent.com/ANOONIMASXP/MOD/data/bin"; do
		if curl -fsSL --retry 2 --retry-delay 2 --retry-all-errors \
			--connect-timeout 15 --max-time 300 --speed-limit 1024 --speed-time 30 \
			-o "$RULESET_COMPILER" "$cbase/ruleset-compiler"; then
			compiler_ok=1
			break
		fi
		log "warning: $cbase 拉取失败，尝试下一源"
	done
	[ "$compiler_ok" -eq 1 ] || die "获取 $RULESET_COMPILER 失败（所有源均失败）"
fi
[ -x "$RULESET_COMPILER" ] || chmod +x "$RULESET_COMPILER"

# 1. 下载（主源失败依次尝试镜像）
download() {
	local name="$1" base n ok=0
	for base in "${BASE_URLS[@]}"; do
		log "fetching $name from $base"
		if curl -fsSL --retry 2 --retry-delay 2 --retry-all-errors \
			--connect-timeout 15 --max-time 300 --speed-limit 1024 --speed-time 30 \
			-o "$WORKDIR/$name" "$base/$name"; then
			ok=1
			break
		fi
		log "warning: $base 拉取失败，尝试下一源"
	done
	[ "$ok" -eq 1 ] || die "下载失败: $name（所有源均失败）"
	n=$(( $(wc -l < "$WORKDIR/$name") ))
	log "downloaded $name: $n lines"
}

download domain.txt

# 2. 下载校验
domain_lines=$(( $(wc -l < "$WORKDIR/domain.txt") ))
[ "$domain_lines" -ge "$DOMAIN_MIN_LINES" ] || die "domain.txt 仅 $domain_lines 行 (< $DOMAIN_MIN_LINES)"

# 3+4. 拆分归一化 domain.txt：||d^ -> ad；@@||[*.]d^[…] -> white
#   拦截侧非标准行 > 0 中止；@@ 行无法解析仅告警跳过
log "splitting domain.txt into ad/white"
: > "$WORKDIR/domain.bad"
: > "$WORKDIR/white.bad"
: > "$WORKDIR/domain.raw"
: > "$WORKDIR/white.raw"
awk -v BAD="$WORKDIR/domain.bad" -v WBAD="$WORKDIR/white.bad" \
	-v AD="$WORKDIR/domain.raw" -v WH="$WORKDIR/white.raw" '
function valid(d,   arr, n, i, lab, alldig) {
	if (length(d) > 253) return 0
	if (d ~ /[^a-z0-9.-]/) return 0
	if (d ~ /^\./ || d ~ /\.$/ || d ~ /\.\./) return 0
	n = split(d, arr, ".")
	if (n < 2) return 0
	alldig = 1
	for (i = 1; i <= n; i++) {
		lab = arr[i]
		if (length(lab) < 1 || length(lab) > 63) return 0
		if (lab ~ /^-/ || lab ~ /-$/) return 0
		if (lab !~ /^[0-9]+$/) alldig = 0
	}
	if (alldig) return 0
	return 1
}
BEGIN { bom = sprintf("%c%c%c", 239, 187, 191) }
{
	line = $0
	if (substr(line, 1, 3) == bom) line = substr(line, 4)
	gsub(/\r/, "", line)
	sub(/^[ \t]+/, "", line)
	sub(/[ \t]+$/, "", line)
	if (line == "") next
	c = substr(line, 1, 1)
	if (c == "!" || c == "#") next
	if (line ~ /^\[[^][]*\]$/) next
	if (substr(line, 1, 2) == "@@") {
		if (line !~ /^@@\|\|(\*\.)?[^|@]+\^(\$[^$]*)?$/) { print line > WBAD; next }
		d = line
		sub(/^@@\|\|/, "", d)
		sub(/^\*\./, "", d)
		sub(/\^.*$/, "", d)
		d = tolower(d)
		if (!valid(d)) { print line > WBAD; next }
		print d > WH
		next
	}
	if (line !~ /^\|\|[^|]+\^$/) { print line > BAD; next }
	d = line
	sub(/^\|\|/, "", d)
	sub(/\^$/, "", d)
	d = tolower(d)
	if (!valid(d)) { print line > BAD; next }
	print d > AD
}
' "$WORKDIR/domain.txt"

domain_bad=$(( $(wc -l < "$WORKDIR/domain.bad") ))
if [ "$domain_bad" -gt 0 ]; then
	log "非法行样例:"
	head -n 5 "$WORKDIR/domain.bad" >&2 || true
	die "domain.txt 存在 $domain_bad 行非标准/非法条目"
fi

white_bad=$(( $(wc -l < "$WORKDIR/white.bad") ))
if [ "$white_bad" -gt 0 ]; then
	log "warning: domain.txt 有 $white_bad 行 @@ 例外无法解析，已跳过"
	head -n 5 "$WORKDIR/white.bad" >&2 || true
fi

sort -u "$WORKDIR/domain.raw" > "$WORKDIR/domain.clean"
sort -u "$WORKDIR/white.raw" > "$WORKDIR/white.clean"

domain_count=$(( $(wc -l < "$WORKDIR/domain.clean") ))
white_count=$(( $(wc -l < "$WORKDIR/white.clean") ))
[ "$domain_count" -ge "$DOMAIN_MIN_LINES" ] || die "拆分后 ad 仅 $domain_count 条 (< $DOMAIN_MIN_LINES)"
if [ "$white_count" -gt $(( domain_count / 10 )) ]; then
	log "warning: white($white_count) ≥ ad($domain_count) 的 10%，上游数据疑似异常"
fi
log "normalized: domain=$domain_count white=$white_count"

# 5. 生成 JSON
jq --rawfile d "$WORKDIR/domain.clean" \
	'.rules[0].domain_suffix = ($d | split("\n") | map(select(length > 0)))' \
	./tem/domain.json > "$WORKDIR/ad.json" || die "生成 ad.json 失败"

if [ "$white_count" -gt 0 ]; then
	jq --rawfile w "$WORKDIR/white.clean" \
		'.rules[0].domain = ($w | split("\n") | map(select(length > 0)))' \
		./tem/white.json > "$WORKDIR/white.json" || die "生成 white.json 失败"
	if grep -q '\$important' "$WORKDIR/white.json"; then
		die "white.json 残留 \$important"
	fi
else
	log "warning: white 列表为空，本次不更新 out/white.*"
fi

# 6. 编译 rule-set
log "compiling rule-sets"
"$RULESET_COMPILER" -o "$WORKDIR/ad.srs" "$WORKDIR/ad.json" || die "编译 ad.srs 失败"
[ -s "$WORKDIR/ad.srs" ] || die "ad.srs 为空"

if [ -f "$WORKDIR/white.json" ]; then
	"$RULESET_COMPILER" -o "$WORKDIR/white.srs" "$WORKDIR/white.json" || die "编译 white.srs 失败"
	[ -s "$WORKDIR/white.srs" ] || die "white.srs 为空"
fi

# 7. 产物校验
jq -e '(.version != null) and (.rules[0].domain_suffix | type == "array")' "$WORKDIR/ad.json" >/dev/null || die "ad.json 结构异常"
ad_out=$(jq '.rules[0].domain_suffix | length' "$WORKDIR/ad.json")
[ "$ad_out" -eq "$domain_count" ] || die "ad.json 条数($ad_out)与归一化结果($domain_count)不一致"

if [ -f "$WORKDIR/white.json" ]; then
	jq -e '(.version != null) and (.rules[0].domain | type == "array")' "$WORKDIR/white.json" >/dev/null || die "white.json 结构异常"
	white_out=$(jq '.rules[0].domain | length' "$WORKDIR/white.json")
	[ "$white_out" -eq "$white_count" ] || die "white.json 条数($white_out)与归一化结果($white_count)不一致"
	blocked_under_white=$(jq -n --slurpfile w "$WORKDIR/white.json" --slurpfile a "$WORKDIR/ad.json" \
		'[ $w[0].rules[0].domain[] as $x | $a[0].rules[0].domain_suffix[] | select(endswith("." + $x)) ] | length')
	[ "$blocked_under_white" -eq 0 ] || log "warning: 黑名单含 $blocked_under_white 条 white 子树条目，精确 domain 将欠放行"
	overlap=$(jq -n --slurpfile w "$WORKDIR/white.json" --slurpfile a "$WORKDIR/ad.json" \
		'[ $w[0].rules[0].domain[] as $x | select($a[0].rules[0].domain_suffix | index($x) != null) ] | length')
	[ "$overlap" -eq 0 ] || log "warning: ad 与 white 精确重叠 $overlap 条（white 先生效，依赖客户端接线顺序）"
fi

# 8. 原子发布到 out/
mkdir -p "$OUT_DIR"
cp "$WORKDIR/ad.json" "$OUT_DIR/.ad.json.tmp"
cp "$WORKDIR/ad.srs" "$OUT_DIR/.ad.srs.tmp"
if [ -f "$WORKDIR/white.json" ]; then
	cp "$WORKDIR/white.json" "$OUT_DIR/.white.json.tmp"
	cp "$WORKDIR/white.srs" "$OUT_DIR/.white.srs.tmp"
fi
mv "$OUT_DIR/.ad.json.tmp" "$OUT_DIR/ad.json"
mv "$OUT_DIR/.ad.srs.tmp" "$OUT_DIR/ad.srs"
if [ -f "$OUT_DIR/.white.json.tmp" ]; then
	mv "$OUT_DIR/.white.json.tmp" "$OUT_DIR/white.json"
	mv "$OUT_DIR/.white.srs.tmp" "$OUT_DIR/white.srs"
fi

elapsed=$(( $(date +%s) - start_ts ))
log "done: domain=$domain_count white=$white_count ad=$(du -h "$OUT_DIR/ad.json" | cut -f1) elapsed=${elapsed}s"
