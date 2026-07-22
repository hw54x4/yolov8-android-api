import os
from flask import Flask, request, jsonify
from ultralytics import YOLO
import cv2
import numpy as np

app = Flask(__name__)

# Load model asli YOLOv8s
model = YOLO("best.pt")

@app.route("/detect", methods=["POST"])
def detect_object():
    if 'image' not in request.files:
        return jsonify({"error": "Tidak ada gambar yang dikirim"}), 400

    file = request.files['image']
    img_bytes = file.read()
    
    # Konversi ke format gambar OpenCV
    nparr = np.frombuffer(img_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    # Deteksi dengan YOLOv8 (resolusi 1280p, confidence 0.25)
    results = model(img, imgsz=1280, conf=0.25)
    
    predictions = []
    for box in results[0].boxes:
        coords = box.xyxy[0].tolist() # [xmin, ymin, xmax, ymax]
        predictions.append({
            "bbox": [int(c) for c in coords],
            "confidence": float(box.conf[0]),
            "label": model.names[int(box.cls[0])]
        })

    return jsonify({"status": "success", "predictions": predictions})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)