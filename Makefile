.PHONY: all kind install_argocd install_ingress_controller deploy test clean

KIND_CONFIG=bootstrap/kind-cluster.yaml
ARGOCD_APP=argocd/application.yaml
INSTALL_DIR=bootstrap
SCRIPTS_DIR=scripts

all: kind install_argocd install_ingress_controller deploy

kind:
	kind create cluster --config $(KIND_CONFIG)

install_argocd:
	./$(INSTALL_DIR)/install-argocd.sh

install_ingress_controller:
	./$(INSTALL_DIR)/install-nginx-ingress-controller.sh

deploy:
	kubectl apply -f $(ARGOCD_APP)

test:
	./$(SCRIPTS_DIR)/test.sh

clean:
	kind delete cluster
