lint:
	black --check .
	isort -c .
	flake8 --max-complexity 10
	bandit -c .bandit.yaml  -r .
	mypy .
	pylint -j 0 cdweb core
	pylint -j 0 -d duplicate-code tests

test:
	pytest -n 2 -vv --cov=. tests/

check: lint test

format_code:
	black .
	isort .
	autoflake --in-place --remove-all-unused-imports -r .

flower:
	docker-compose run --rm --service-ports flower

shell:
	./manage.py shell_plus --ipython
