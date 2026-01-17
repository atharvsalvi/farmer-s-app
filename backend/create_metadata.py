import json
import os

metadata = {
    "Apple___Apple_scab": {
        "name": "Apple Scab",
        "status": "Unhealthy",
        "causes": ["Fungus Venturia inaequalis", "Overwintering in fallen leaves", "Wet spring weather"],
        "prevention": ["Rake and destroy fallen leaves", "Fungicide application", "Plant resistant varieties"]
    },
    "Apple___Black_rot": {
        "name": "Apple Black Rot",
        "status": "Unhealthy",
        "causes": ["Fungus Botryosphaeria obtusa", "Infection of wounds", "Warm, moist weather"],
        "prevention": ["Prune dead wood", "Remove mummified fruit", "Fungicide sprays"]
    },
    "Apple___Cedar_apple_rust": {
        "name": "Cedar Apple Rust",
        "status": "Unhealthy",
        "causes": ["Fungus Gymnosporangium juniperi-virginianae", "Proximity to cedar trees"],
        "prevention": ["Remove nearby cedar trees", "Fungicide application", "Resistant apple varieties"]
    },
    "Apple___healthy": {
        "name": "Healthy Apple",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Maintain regular care", "Monitor for pests"]
    },
    "Blueberry___healthy": {
        "name": "Healthy Blueberry",
        "status": "Healthy",
        "causes": [],
        "prevention": [" proper irrigation", "Regular pruning"]
    },
    "Cherry_(including_sour)___Powdery_mildew": {
        "name": "Cherry Powdery Mildew",
        "status": "Unhealthy",
        "causes": ["Fungus Podosphaera clandestina", "High humidity"],
        "prevention": ["Prune for airflow", "Fungicide sprays", "Remove infected debris"]
    },
    "Cherry_(including_sour)___healthy": {
        "name": "Healthy Cherry",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Regular watering", "Fertilization"]
    },
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": {
        "name": "Corn Gray Leaf Spot",
        "status": "Unhealthy",
        "causes": ["Fungus Cercospora zeae-maydis", "Crop residue"],
        "prevention": ["Crop rotation", "Resistant hybrids", "Tillage"]
    },
    "Corn_(maize)___Common_rust_": {
        "name": "Corn Common Rust",
        "status": "Unhealthy",
        "causes": ["Fungus Puccinia sorghi", "Cool, moist weather"],
        "prevention": ["Resistant hybrids", "Fungicides (if severe)"]
    },
    "Corn_(maize)___Northern_Leaf_Blight": {
        "name": "Corn Northern Leaf Blight",
        "status": "Unhealthy",
        "causes": ["Fungus Exserohilum turcicum", "Wet, humid weather"],
        "prevention": ["Resistant hybrids", "Crop rotation", "Fungicides"]
    },
    "Corn_(maize)___healthy": {
        "name": "Healthy Corn",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Proper irrigation", "Nutrient management"]
    },
    "Grape___Black_rot": {
        "name": "Grape Black Rot",
        "status": "Unhealthy",
        "causes": ["Fungus Guignardia bidwellii", "Humid weather"],
        "prevention": ["Remove mummified berries", "Canopy management", "Fungicides"]
    },
    "Grape___Esca_(Black_Measles)": {
        "name": "Grape Esca (Black Measles)",
        "status": "Unhealthy",
        "causes": ["Complex of fungi", "Pruning wounds"],
        "prevention": ["Protect pruning wounds", "Remove infected vines", "Avoid stress"]
    },
    "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)": {
        "name": "Grape Leaf Blight",
        "status": "Unhealthy",
        "causes": ["Fungus Isariopsis clavispora", "Wet conditions"],
        "prevention": ["Fungicides", "Sanitation"]
    },
    "Grape___healthy": {
        "name": "Healthy Grape",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Regular pruning", "Pest monitoring"]
    },
    "Orange___Haunglongbing_(Citrus_greening)": {
        "name": "Citrus Greening (Huanglongbing)",
        "status": "Unhealthy",
        "causes": ["Bacteria Candidatus Liberibacter", "Asian citrus psyllid vector"],
        "prevention": ["Control psyllids", "Remove infected trees", "Use disease-free nursery stock"]
    },
    "Peach___Bacterial_spot": {
        "name": "Peach Bacterial Spot",
        "status": "Unhealthy",
        "causes": ["Bacteria Xanthomonas campestris", "Wind and rain"],
        "prevention": ["Resistant varieties", "Copper sprays", "Proper fertilization"]
    },
    "Peach___healthy": {
        "name": "Healthy Peach",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Pruning", "Thinning fruit"]
    },
    "Pepper,_bell___Bacterial_spot": {
        "name": "Pepper Bacterial Spot",
        "status": "Unhealthy",
        "causes": ["Bacteria Xanthomonas euvesicatoria", "Warm, wet weather"],
        "prevention": ["Disease-free seeds", "Copper sprays", "Crop rotation"]
    },
    "Pepper,_bell___healthy": {
        "name": "Healthy Bell Pepper",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Proper spacing", "Weed control"]
    },
    "Potato___Early_blight": {
        "name": "Potato Early Blight",
        "status": "Unhealthy",
        "causes": ["Fungus Alternaria solani", "Stressed plants"],
        "prevention": ["Crop rotation", "Fungicides", "Proper irrigation"]
    },
    "Potato___Late_blight": {
        "name": "Potato Late Blight",
        "status": "Unhealthy",
        "causes": ["Oomycete Phytophthora infestans", "Cool, wet weather"],
        "prevention": ["Resistant varieties", "Fungicides", "Eliminate cull piles"]
    },
    "Potato___healthy": {
        "name": "Healthy Potato",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Certified seed potatoes", "Hilling"]
    },
    "Raspberry___healthy": {
        "name": "Healthy Raspberry",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Pruning", "Mulching"]
    },
    "Soybean___healthy": {
        "name": "Healthy Soybean",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Crop rotation", "Weed management"]
    },
    "Squash___Powdery_mildew": {
        "name": "Squash Powdery Mildew",
        "status": "Unhealthy",
        "causes": ["Fungus Podosphaera xanthii", "High humidity", "Poor air circulation"],
        "prevention": ["Resistant varieties", "Fungicides", "Space plants properly"]
    },
    "Strawberry___Leaf_scorch": {
        "name": "Strawberry Leaf Scorch",
        "status": "Unhealthy",
        "causes": ["Fungus Diplocarpon earliana", "Wet conditions"],
        "prevention": ["Remove infected leaves", "Fungicides", "Improve drainage"]
    },
    "Strawberry___healthy": {
        "name": "Healthy Strawberry",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Renew beds", "Mulching"]
    },
    "Tomato___Bacterial_spot": {
        "name": "Tomato Bacterial Spot",
        "status": "Unhealthy",
        "causes": ["Bacteria Xanthomonas", "Wet foliage"],
        "prevention": ["Copper sprays", "Avoid overhead watering", "Disease-free seeds"]
    },
    "Tomato___Early_blight": {
        "name": "Tomato Early Blight",
        "status": "Unhealthy",
        "causes": ["Fungus Alternaria solani", "Warm, wet weather"],
        "prevention": ["Stake plants", "Mulch", "Fungicides"]
    },
    "Tomato___Late_blight": {
        "name": "Tomato Late Blight",
        "status": "Unhealthy",
        "causes": ["Oomycete Phytophthora infestans", "Cool, wet nights"],
        "prevention": ["Fungicides", "Remove infected plants", "Avoid overhead irrigation"]
    },
    "Tomato___Leaf_Mold": {
        "name": "Tomato Leaf Mold",
        "status": "Unhealthy",
        "causes": ["Fungus Passalora fulva", "High humidity in greenhouses"],
        "prevention": ["Ventilation", "Fungicides", "Resistant varieties"]
    },
    "Tomato___Septoria_leaf_spot": {
        "name": "Tomato Septoria Leaf Spot",
        "status": "Unhealthy",
        "causes": ["Fungus Septoria lycopersici", "Wet lower leaves"],
        "prevention": ["Remove lower leaves", "Mulch", "Fungicides"]
    },
    "Tomato___Spider_mites Two-spotted_spider_mite": {
        "name": "Tomato Two-spotted Spider Mite",
        "status": "Unhealthy",
        "causes": ["Mite Tetranychus urticae", "Hot, dry weather"],
        "prevention": ["Miticides", "Water sprays", "Predatory mites"]
    },
    "Tomato___Target_Spot": {
        "name": "Tomato Target Spot",
        "status": "Unhealthy",
        "causes": ["Fungus Corynespora cassiicola", "High humidity"],
        "prevention": ["Fungicides", "Air circulation", "Remove residue"]
    },
    "Tomato___Tomato_Yellow_Leaf_Curl_Virus": {
        "name": "Tomato Yellow Leaf Curl Virus",
        "status": "Unhealthy",
        "causes": ["Virus", "Whitefly vector"],
        "prevention": ["Control whiteflies", "Reflective mulches", "Resistant varieties"]
    },
    "Tomato___Tomato_mosaic_virus": {
        "name": "Tomato Mosaic Virus",
        "status": "Unhealthy",
        "causes": ["Virus", "Mechanical transmission", "Contaminated seeds"],
        "prevention": ["Sanitation", "Certified seed", "Resistant varieties"]
    },
    "Tomato___healthy": {
        "name": "Healthy Tomato",
        "status": "Healthy",
        "causes": [],
        "prevention": ["Regular watering", "Support/staking"]
    }
}

os.makedirs('Models', exist_ok=True)
with open('Models/disease_info.json', 'w') as f:
    json.dump(metadata, f, indent=4)

print("Metadata created at Models/disease_info.json")
