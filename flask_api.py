#   Metty Kapgen
import json
import random
from flask import Flask, request, jsonify, Response

app = Flask(__name__)

#   GET query, returns a random user_id and latitude an longitude values
@app.route('/', methods=['GET'])
def query_records():
    return {"userId": random.randint(0,100), "lat": random.uniform(-10,10), "lon": random.uniform(-10,10)}

#   POST query, prints the received data
@app.route('/', methods=['POST'])
def update_record():
    record = json.loads(request.data)
    print(record)
    return Response("{}", status= 201, mimetype="application/json")

app.run(debug=True)