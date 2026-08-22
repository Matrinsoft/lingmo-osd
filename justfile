name := 'cosmic-osd'
rootdir := ''
prefix := '/usr'
polkit-agent-helper-1 := '/usr/libexec/polkit-agent-helper-1'
cargo-target-dir := env('CARGO_TARGET_DIR', 'target')

base-dir := absolute_path(clean(rootdir / prefix))
bin-dst := base-dir / 'bin' / name

# Default recipe which runs `just build-release`
[private]
default: build-release

# Compiles with debug profile
build-debug *args:
    env POLKIT_AGENT_HELPER_1={{polkit-agent-helper-1}} cargo build {{args}}

# Compiles with release profile
build-release *args: (build-debug '--release' args)

# Compiles with vendored dependencies
build-vendored *args:
    @just vendor-extract
    cargo build --release {{ args }} --frozen --offline

# Build a debian package locally without a schroot or vendoring
build-deb:
    dpkg-buildpackage -d -nc

# Runs `cargo clean`
clean:
    cargo clean

# `cargo clean` and removes vendored dependencies
clean-dist: clean
    rm -rf .cargo vendor vendor.tar

# Runs a clippy check
check *args:
    cargo clippy --all-features {{args}} -- -W clippy::pedantic

# Runs a clippy check with JSON message format
check-json: (check '--message-format=json')

# Installs files
install:
    install -Dm0755 {{ cargo-target-dir / 'release' / name }} {{bin-dst}}

# Vendor Cargo dependencies locally
vendor:
	mkdir -p .cargo
	cargo vendor --locked 2>/dev/null | awk '/^\[/{p=1} p' > .cargo/config.toml
	if ! grep -q 'directory' .cargo/config.toml 2>/dev/null; then
	echo '[source.crates-io]' >> .cargo/config.toml
	echo 'replace-with = "vendored-sources"' >> .cargo/config.toml
	echo '' >> .cargo/config.toml
	echo '[source.vendored-sources]' >> .cargo/config.toml
	echo 'directory = "vendor"' >> .cargo/config.toml
	fi
	grep '^source = "git+" Cargo.lock | sed 's/source = "//;s/"$//' | sort -u | while read src; do \
	echo "[source \"$src\"]"; \
	echo 'replace-with = "vendored-sources"'; \
	echo ""; \
	done >> .cargo/config.toml
	tar pcf vendor.tar vendor .cargo/config.toml
	rm -rf vendor

# Extracts vendored dependencies
[private]
vendor-extract:
    #!/usr/bin/env sh
    rm -rf vendor
    tar pxf vendor.tar
