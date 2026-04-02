RELEASE := 0.13.3

all: build


build:
	docker build -t aifajupyter/aifa-jupyter-python-tutorial-release-$(RELEASE) .


push:
	docker push aifajupyter/aifa-jupyter-python-tutorial-release-$(RELEASE)
