.PHONY: clean
all: .build

clean:
	docker rmi `docker images -f "dangling=true" -q`

.build: Dockerfile
	docker build -t android-builder .
