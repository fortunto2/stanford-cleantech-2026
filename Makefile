lab:
	uv run jupyter lab --no-browser --port 8890 --ServerApp.token=cleantech --ServerApp.allow_origin=https://colab.research.google.com --ServerApp.port_retries=0 --ServerApp.disable_check_xsrf=True
plan:
	uv run python -m crewair.cli "$(P)" --shift $(or $(S),07-17)
test:
	uv run --with pytest pytest -q tests
