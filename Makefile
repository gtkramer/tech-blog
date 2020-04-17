.PHONY: all
all:
	command -v pygmentize
	hugo gen chromastyles --style=github > syntax.css
	hugo
