
all: up

up:
	docker compose up -d

down:
	docker compose down

clean: down
	docker image prune -af
	docker volume prune -af
	docker network prune -f

logs:
	docker compose logs -f

re: clean up

.PHONY: all up down clean logs re