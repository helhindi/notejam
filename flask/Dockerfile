FROM python:3.8-slim-buster AS build
COPY . /notejam/flask
WORKDIR /notejam/flask

# Install dependencies:
RUN pip install -r requirements.txt

ADD start.sh /
RUN chmod +x /start.sh
CMD [ "/start.sh" ]
