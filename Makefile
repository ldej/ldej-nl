run:
	hugo server -D

build:
	hugo

resume:	build
	cat public/resume/index.html| wkhtmltopdf - ./static/Laurence.de.Jong-resume.pdf

# webp
# cwebp IMG_20190916_142011.jpg -o ladakh5.webp