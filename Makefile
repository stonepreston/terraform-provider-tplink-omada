provider_install_path = $(HOME)/.terraform.d/plugins/registry.terraform.io/tplink/omada/0.1.0/$(shell go env GOOS)_$(shell go env GOARCH)

.PHONY: build install clean test

build:
	go build -o terraform-provider-omada

install: build
	mkdir -p $(provider_install_path)
	cp terraform-provider-omada $(provider_install_path)/terraform-provider-omada

clean:
	rm -f terraform-provider-omada

test:
	go test ./...

fmt:
	go fmt ./...

vet:
	go vet ./...
