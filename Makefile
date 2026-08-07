STACKS := python javascript cpp csharp container helm ansible terraform

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Install the git hooks and build every hook environment
	pre-commit install --install-hooks

.PHONY: run
run: ## Run the root config over every file (what CI does)
	SKIP=no-commit-to-branch pre-commit run --all-files --show-diff-on-failure

.PHONY: run-push
run-push: ## Run the pre-push-stage hooks
	pre-commit run --hook-stage pre-push --all-files

.PHONY: run-manual
run-manual: ## Run the slow/networked manual-stage hooks
	pre-commit run --hook-stage manual --all-files

.PHONY: stacks
stacks: ## Run every standalone stack config in an isolated repo
	@for stack in $(STACKS); do ./scripts/run-stack.sh $$stack || exit 1; done

.PHONY: $(STACKS)
$(STACKS): ## Run one stack's standalone config (e.g. `make terraform`)
	./scripts/run-stack.sh $@

.PHONY: test
test: ## Test the repo-local hooks
	python -m pytest hooks/tests -q

.PHONY: update
update: ## pre-commit autoupdate across the root and all stack configs
	pre-commit autoupdate
	@for stack in $(STACKS); do \
		echo "==> stacks/$$stack"; \
		pre-commit autoupdate --config stacks/$$stack/.pre-commit-config.yaml; \
	done

.PHONY: clean
clean: ## Drop the pre-commit cache
	pre-commit clean
	pre-commit gc
