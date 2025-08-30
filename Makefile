# go makefile

#
# common config 
#

program != basename $$(pwd)
version != cat VERSION
latest_release := $(shell gh 2>/dev/null release list --json tagName --jq '.[0].tagName' | tr -d v)
rstms_modules != awk <go.mod '/^module/{next} /rstms/{print $$1}'
latest_module_release = $(shell gh --repo $(1) release list --json tagName --jq '.[0].tagName')
gitclean = $(if $(shell git status --porcelain),$(error git status is dirty),$(info git status is clean))


#
# project config 
#

openbsd_netboot_iso = template/ipxe/openbsd-7.5-amd64.iso template/ipxe/openbsd-7.6-amd64.iso template/ipxe/openbsd-7.7-amd64.iso 
keymaster = template/certs/keymaster.pem
debian_cacerts = template/certs/cacerts.tgz
generated_template_files = $(keymaster) $(debian_cacerts) $(openbsd_netboot_iso)


#
# common targets
#

$(program): build

build: fmt
	fix go build . ./...
	go build

fmt: go.sum
	fix go fmt . ./...

go.mod:
	go mod init

go.sum: go.mod
	go mod tidy

install: build
	go install

test: fmt
	go test -v -failfast . ./...

debug: fmt
	go test -v -failfast -count=1 -run $(test) . ./...

release:
	$(gitclean)
	@$(if $(update),gh release delete -y v$(version),)
	gh release create v$(version) --notes "v$(version)"

update:
	@echo checking dependencies for updated versions
	@echo "rstms_modules=$(rstms_modules)"
	@curl -s -L -o cmd/common.go https://raw.githubusercontent.com/rstms/go-common/master/proxy_common_go
	sed <cmd/common.go >template/common.go 's/^package cmd/package template/'
	@$(foreach m,$(rstms_modules),go get $(m)@$(call latest_module_release,$(m));)

clean:
	rm -f $(program) *.core 
	go clean

sterile: clean
	which $(program) && go clean -i || true
	go clean
	go clean -cache
	go clean -modcache
	rm -f go.mod go.sum


# project targets

gen: $(generated_template_files)

regen: 
	rm -f $(generated_template_files)
	$(MAKE) gen


$(keymaster): /etc/ssl/keymaster.pem
	cp $< $@

$(debian_cacerts): $(keymaster)
	scripts/hash_debian_cacerts

template/ipxe/openbsd-7.5-amd64.iso: template/dist/openbsd/7.5/amd64/cd75.iso $(wildcard template/mkboot/*.openbsd)
	scripts/generate_openbsd_netboot_iso 7.5 amd64

template/ipxe/openbsd-7.6-amd64.iso: template/dist/openbsd/7.6/amd64/cd76.iso $(wildcard template/mkboot/*.openbsd)
	scripts/generate_openbsd_netboot_iso 7.6 amd64

template/ipxe/openbsd-7.7-amd64.iso: template/dist/openbsd/7.7/amd64/cd77.iso $(wildcard template/mkboot/*.openbsd)
	scripts/generate_openbsd_netboot_iso 7.7 amd64

