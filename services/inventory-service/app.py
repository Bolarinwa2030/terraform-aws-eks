from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "inventory-service"})

@app.route('/inventory')
def inventory():
    return jsonify({"items": [{"id": 1, "name": "laptop", "stock": 50}]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
