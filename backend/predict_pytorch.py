import torch
import torch.nn as nn
from torchvision import transforms
from PIL import Image
import json
import os
import sys

# ==========================================
# 1. Re-Define the Model Architecture
# (Must match exactly what you trained with)
# ==========================================
class MyCNNModel(nn.Module):
    def __init__(self, num_classes):
        super(MyCNNModel, self).__init__()
        
        self.con_layers = nn.Sequential(
            nn.Conv2d(3, 16, 3, 1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(16, 32, 3, 1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2),
            nn.Conv2d(32, 64, 3, 1),
            nn.ReLU(),
            nn.MaxPool2d(2, 2)
        )
        self.adaptive_pool = nn.AdaptiveAvgPool2d((7, 7))

        self.layers = nn.Sequential(
            nn.Flatten(),
            nn.Linear(64 * 7 * 7, 256),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(256, num_classes)
        )

    def forward(self, x):
        x = self.con_layers(x)
        x = self.adaptive_pool(x)
        x = self.layers(x)
        return x

# ==========================================
# 2. Prediction Setup
# ==========================================
MODEL_PATH = "Models/plant_disease_model_final.pth" # Updated to point to Models folder
METADATA_PATH = "Models/disease_info.json" # Ensure you ran create_metadata.py
DATASET_PATH = "Datasets/PlantDocBot_Dataset/train" # Needed to get class names

def get_class_names(dataset_path):
    """
    Reads the folder names to reconstruct the class list.
    Crucial: The order must be alphabetical to match PyTorch's ImageFolder.
    """
    if not os.path.exists(dataset_path):
        print(f"❌ Error: Could not find dataset at {dataset_path} to read class names.")
        return []
    
    classes = [d for d in os.listdir(dataset_path) if os.path.isdir(os.path.join(dataset_path, d))]
    classes.sort() # PyTorch sorts classes alphabetically
    return classes

def load_trained_model(num_classes):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = MyCNNModel(num_classes=num_classes)
    
    if not os.path.exists(MODEL_PATH):
        print(f"❌ Error: Model file '{MODEL_PATH}' not found. Train your model first!")
        sys.exit(1)

    # Load weights
    model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    model.to(device)
    model.eval() # Set to evaluation mode (turns off Dropout)
    return model, device

def predict_image(image_path):
    # 1. Get Class Names
    class_names = get_class_names(DATASET_PATH)
    if not class_names:
        return

    # 2. Load Model
    model, device = load_trained_model(len(class_names))

    # 3. Load Metadata (Optional)
    disease_info = {}
    if os.path.exists(METADATA_PATH):
        with open(METADATA_PATH, 'r') as f:
            disease_info = json.load(f)

    # 4. Preprocess Image
    transform = transforms.Compose([
        transforms.Resize((128, 128)), # Must match training size
        transforms.ToTensor(),
    ])

    if not os.path.exists(image_path):
        print(f"❌ Error: Image '{image_path}' not found.")
        return

    image = Image.open(image_path).convert('RGB')
    image_tensor = transform(image).unsqueeze(0).to(device) # Add batch dimension

    # 5. Predict
    with torch.no_grad():
        output = model(image_tensor)
        probabilities = torch.nn.functional.softmax(output, dim=1)
        confidence, predicted_idx = torch.max(probabilities, 1)

    predicted_label = class_names[predicted_idx.item()]
    conf_score = confidence.item()

    # 6. Output Results
    result = {
        "detected": predicted_label,
        "confidence": conf_score,
        "status": "Unknown",
        "disease": predicted_label,
        "prevention": []
    }

    info = disease_info.get(predicted_label)
    if info:
        result["status"] = info.get('status', 'Unknown')
        result["disease"] = info.get('name', predicted_label)
        result["prevention"] = info.get('prevention', [])
        result["causes"] = info.get('causes', [])
    
    # Print ONLY the JSON to stdout
    print(json.dumps(result))

if __name__ == "__main__":
    if len(sys.argv) < 2:
        # print("Usage: python predict_pytorch.py <path_to_image.jpg>", file=sys.stderr)
        sys.exit(1)
    else:
        # Suppress potential warnings from libraries
        import warnings
        warnings.filterwarnings("ignore")
        predict_image(sys.argv[1])
