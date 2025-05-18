
all: up

up:
	docker compose up

down:
	docker compose down

clean: down
	docker image prune -af
	docker volume prune -af
	docker network prune -f

re: clean up