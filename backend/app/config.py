class Config:
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://user:password@db:3306/home_automation'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = 'your-secret-key'

