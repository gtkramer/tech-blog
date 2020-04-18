.PHONY: all
all:
	command -v pygmentize
	rm -rf public
	hugo gen chromastyles --style=github > syntax.css
	hugo
