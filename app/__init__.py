from flask import Flask
from config import Config
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////opt/url-shortener/test.db'
app.config.from_object(Config)
app.config['SESSION_TYPE'] = 'filesystem'
app.secret_key = 'mysupersecretkey'

db = SQLAlchemy(app)
migrate = Migrate(app, db)

from app import routes
