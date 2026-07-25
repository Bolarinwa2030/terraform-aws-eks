from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "api-gateway"})

@app.route('/')
def root():
    return jsonify({"message": "api-gateway is running", "routes": ["/orders", "/inventory"]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)