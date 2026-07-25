from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "order-service"})

@app.route('/orders')
def orders():
    return jsonify({"orders": [{"id": 1, "item": "laptop", "status": "pending"}]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF