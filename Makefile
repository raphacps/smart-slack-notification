.PHONY: run
run:
	docker compose build && docker compose up

.PHONY: deploy
deploy:
	docker compose build && docker compose push