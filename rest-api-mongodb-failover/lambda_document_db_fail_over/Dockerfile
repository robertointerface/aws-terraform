FROM public.ecr.aws/lambda/python:3.12
ENV WORKING_DIR=${LAMBDA_TASK_ROOT}
WORKDIR ${LAMBDA_TASK_ROOT}

# TODO need to add non-root user to run commands inside docker
#RUN groupadd -r appgroup && useradd -r -g appgroup appuser
#USER appuser

RUN pip install poetry==1.8.3

RUN poetry config virtualenvs.create true
RUN poetry config virtualenvs.in-project true

COPY ./pyproject.toml ${WORKING_DIR}/
COPY ./poetry.lock ${WORKING_DIR}/

RUN poetry install --no-root && rm -rf $POETRY_CACHE_DIR
ENV PATH=/${WORKING_DIR}/.venv/bin:$PATH
COPY ./src ${WORKING_DIR}/src
RUN poetry install
CMD ["src.lambda_handler.lambda_handler"]