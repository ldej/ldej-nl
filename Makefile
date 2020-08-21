# sudo apt install imagemagick cwebp

run:
	hugo server -D

build:
	hugo

resume:	build
	cat public/resume/index.html| wkhtmltopdf - ./static/Laurence.de.Jong-resume.pdf

# resize to 1440
# convert static/images/bolivia2.jpg -resize 1440x static/images/bolivia2.1440.jpg
# webp
# cwebp IMG_20190916_142011.jpg -o ladakh5.webp