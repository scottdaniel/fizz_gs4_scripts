#!/usr/bin/env bash
#
# Ruby4Lich5 — glib2 in-place patch (macOS)
# ------------------------------------------------------------------------------
# Applies the GC/property-retention fix (cache-ruby-property-setter-values) to the
# INSTALLED glib2 gem, recompiles its native extension in place, and swaps the
# loaded bundle. The rest of the ruby-gnome stack (gtk3, etc.) picks up the patched
# behavior at runtime — no rebuild of the other gems needed.
#
# Uses your default (rbenv global) ruby — the one most users already run; no
# version juggling, just run it. (Targets the glib2 GEM version below, not a ruby.)
# Requires: Xcode Command Line Tools + Homebrew gtk+3/glib (build-on-machine path).
# Idempotent. macOS only (Linux is a separate layer, not plumbed here).
#
# Caveat: a later `gem install glib2 -v <ver>` reverts to stock — just re-run this.
# Revert deliberately: gem install glib2 -v <ver> --force
# ------------------------------------------------------------------------------
set -uo pipefail

GLIB2_VERSION="${GLIB2_VERSION:-4.3.6}"          # override via env if needed
[[ "$GLIB2_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] \
  || { echo "ERROR: GLIB2_VERSION must be semver (e.g. 4.3.6), got: $GLIB2_VERSION"; exit 1; }
PATCH_MARK="G_CHILD_SET(rb_object"               # presence => already patched

LOG_DIR="$HOME/Library/Logs/Ruby4Lich5"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/glib2-patch-$(date +%Y%m%d-%H%M%S).log"

log()     { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }
section() { echo; log "== $* =="; }
fail()    { log "ERROR: $*"; exit 1; }

run() {
  log "Ruby4Lich5 glib2 patch (macOS) — target glib2 $GLIB2_VERSION"

  [ "$(uname -s)" = "Darwin" ] || fail "macOS only (got $(uname -s))."

  # --- environment / instrumentation -----------------------------------------
  section "Environment"
  local arch brew
  arch="$(uname -m)"
  log "macOS $(sw_vers -productVersion)   arch $arch"
  log "ruby  $(ruby -v 2>&1)"
  log "gem home $(gem env home 2>/dev/null)"
  command -v rbenv >/dev/null && log "rbenv $(rbenv version 2>/dev/null)"
  if command -v brew >/dev/null; then brew="$(brew --prefix)"
  elif [ "$arch" = "arm64" ]; then brew="/opt/homebrew"; else brew="/usr/local"; fi
  log "homebrew prefix $brew"
  export PKG_CONFIG_PATH="$brew/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

  # --- build tools ------------------------------------------------------------
  section "Build tools"
  xcode-select -p >/dev/null 2>&1 || fail "Xcode CLT missing.  Install:  xcode-select --install"
  log "Xcode CLT $(xcode-select -p)"
  command -v cc   >/dev/null || fail "no C compiler on PATH."
  command -v make >/dev/null || fail "make not found."
  command -v pkg-config >/dev/null || fail "pkg-config not found.  Install:  brew install pkg-config"
  log "compiler  $(cc --version 2>&1 | head -1)"
  log "make      $(make --version 2>&1 | head -1)"
  log "pkg-config $(pkg-config --version)"

  # --- system libraries (this version table is your drift tracker) -----------
  section "System libraries (pkg-config --modversion)"
  local lib v missing=0
  for lib in glib-2.0 gobject-2.0 gobject-introspection-1.0 gtk+-3.0 cairo pango; do
    if v="$(pkg-config --modversion "$lib" 2>/dev/null)"; then log "  $lib = $v"
    else log "  $lib = MISSING"; missing=1; fi
  done
  [ "$missing" -eq 0 ] || fail "missing system libs.  Install:  brew install gtk+3 gobject-introspection"

  # --- locate the installed glib2 --------------------------------------------
  section "Locate glib2 $GLIB2_VERSION"
  local gemdir src
  gemdir="$(ruby -e "puts Gem::Specification.find_by_name('glib2','=$GLIB2_VERSION').gem_dir" 2>/dev/null)" \
    || fail "glib2 $GLIB2_VERSION not installed under this ruby.  Install:  gem install gtk3 -v $GLIB2_VERSION"
  log "gem dir $gemdir"
  src="$gemdir/ext/glib2/rbgobj_object.c"
  [ -f "$src" ] || fail "source not found: $src"

  # --- patch (idempotent, anchor-verified) -----------------------------------
  section "Patch source"
  ruby - "$src" <<'RUBY'
    p = ARGV[0]; s = File.read(p)
    if s.include?("G_CHILD_SET(rb_object"); puts "already patched (source)"; exit 0; end
    old = "    rb_funcall(GOBJ2RVAL(object), ruby_setter, 1, GVAL2RVAL(value));"
    n = s.scan(old).size
    abort("anchor not found/unique (count=#{n}); glib2 version mismatch?") unless n == 1
    new = ["    {",
    "        VALUE rb_object = GOBJ2RVAL(object);",
    "        VALUE rb_value = GVAL2RVAL(value);",
    "        rb_funcall(rb_object, ruby_setter, 1, rb_value);",
    "        if (G_TYPE_IS_OBJECT(G_PARAM_SPEC_VALUE_TYPE(pspec))) {",
    "            G_CHILD_SET(rb_object, rb_intern(g_param_spec_get_name(pspec)), rb_value);",
    "        }",
    "    }"].join("\n")
    File.write(p, s.sub(old, new)); puts "patched source"
RUBY
  [ $? -eq 0 ] || fail "patch step failed (see above)."
  grep -q "$PATCH_MARK" "$src" || fail "patch marker absent after patch."
  log "patch present in source"

  # --- recompile in place -----------------------------------------------------
  section "Recompile glib2 extension"
  ( cd "$gemdir/ext/glib2" && ruby extconf.rb && make ) || fail "compile failed (full output above)."
  local bundle="$gemdir/ext/glib2/glib2.bundle"
  [ -f "$bundle" ] || fail "glib2.bundle not produced."
  log "compiled $bundle"

  # --- swap the loaded bundle -------------------------------------------------
  section "Install patched bundle"
  local loaded
  loaded="$(ruby -e "require 'glib2'; puts \$LOADED_FEATURES.grep(/glib2\.(bundle|so)\z/).first" 2>/dev/null)" \
    || fail "could not resolve the loaded glib2 bundle path."
  log "loaded bundle $loaded"
  local backup="./glib2.bundle.bak-$(date +%Y%m%d-%H%M%S)"
  cp -f "$loaded" "$backup" || fail "failed to back up original bundle to $backup."
  log "original bundle backed up to $backup"
  cp -f "$bundle" "$loaded" || fail "failed to copy patched bundle into place."
  log "patched bundle installed"

  # --- verify -----------------------------------------------------------------
  section "Verify"
  ruby -e "require 'glib2'; require 'gtk3'; puts 'load OK: ' + RUBY_DESCRIPTION" \
    || fail "stack failed to load after patch."

  section "Done"
  log "glib2 $GLIB2_VERSION patched + loaded."
}

run 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}
echo
if [ "$status" -eq 0 ]; then
  echo "✅ Done.  Log: $LOG"
else
  echo "❌ Failed.  Please share this log:"
  echo "   $LOG"
  echo "   (reveal in Finder:  open -R \"$LOG\" )"
fi
exit "$status"
