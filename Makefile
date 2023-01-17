install:
	go install -tags extended github.com/gohugoio/hugo@latest
	npm install -g firebase-tools

run:
	hugo server -D

build:
	hugo

resume:	build
	cat public/resume/index.html | wkhtmltopdf - ./static/Laurence.de.Jong-resume.pdf

images:
	bash ./scripts/process_images.sh
