# ------------------------------------------------------------
# Makefile pour workstation-provisioning
# ------------------------------------------------------------

TARGET ?= localhost
SCRIPT = ./provision-workstation.sh

.PHONY: help run check dry tags list-tags galaxy-install lint libvirt-fix arbo test-vagrant test

help:
	@echo "Commandes disponibles :"
	@echo "  make run                 Lance le provisioning complet"
	@echo "  make check               Lance Ansible en mode --check"
	@echo "  make dry                 Simule l'exécution (dry-run)"
	@echo "  make tags TAGS=x         Lance uniquement certains tags"
	@echo "  make list-tags           Affiche les tags disponibles"
	@echo "  make galaxy-install      Installe les rôles Galaxy"
	@echo "  make lint                Vérifie la syntaxe Ansible"
	@echo "  make libvirt-fix         Applique uniquement la recette libvirt/firewalld"
	@echo "  make test-vagrant        Lance le test d'intégration Vagrant/libvirt"
	@echo "  make test                Lance tous les tests"
	@echo "  make arbo                Génère l'arborescence du projet"
	@echo ""
	@echo "Exemples :"
	@echo "  make tags TAGS=git"
	@echo "  make tags TAGS=packages,git"
	@echo "  make libvirt-fix TARGET=vagrantvm"
	@echo "  make test-vagrant"
	@echo "  make arbo"

run:
	$(SCRIPT) $(if $(TAGS),--tags "$(TAGS)") --target "$(TARGET)"

check:
	$(SCRIPT) --check --target "$(TARGET)"

dry:
	$(SCRIPT) --dry-run --target "$(TARGET)"

tags:
	$(SCRIPT) --tags "$(TAGS)" --target "$(TARGET)"

list-tags:
	ansible-playbook site.yml --list-tags

galaxy-install:
	ansible-galaxy install -r requirements.yml

lint:
	ansible-playbook site.yml --syntax-check

# ------------------------------------------------------------
# Cible pratique : appliquer uniquement la recette libvirt/firewalld
# ------------------------------------------------------------
libvirt-fix:
	$(SCRIPT) --tags "libvirt_fix" --target "$(TARGET)"

# ------------------------------------------------------------
# Tests d'intégration
# ------------------------------------------------------------
test-vagrant:
	ansible-playbook tests/virtualization_test.yml --tags virtualization_test

test: test-vagrant

# ------------------------------------------------------------
# Génération de l'arborescence du projet
# ------------------------------------------------------------
arbo:
	@tree -a --prune -I ".git|.ansible|logs|.vault" . > workstation-provisioning.txt
	@echo "Arborescence générée dans workstation-provisioning.txt"
