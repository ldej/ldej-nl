run:
	hugo server -D

build:
	hugo

resume:	build
	cat public/resume/index.html| wkhtmltopdf - ./static/Laurence.de.Jong-resume.pdf