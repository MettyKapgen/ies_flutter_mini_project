from flask import Flask
from flask_restful import Api, Resource

app = Flask(__name__)
api = Api(app)

class HelloWorld(Resource):
    def get(self):
        return {"userId": 42, "lat": 5, "lon": 7}
    
api.add_resource(HelloWorld, "/getter")

if __name__ == "__main__":
    app.run(debug=True)