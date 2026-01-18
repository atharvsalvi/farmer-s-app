require('dotenv').config();
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const twilio = require('twilio');

const app = express();
const port = 3000;

// Enable CORS for all routes (allows Flutter Web to call this)
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// TWILIO CREDENTIALS
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioNumber = process.env.TWILIO_PHONE_NUMBER;

const client = new twilio(accountSid, authToken);

app.post('/send-otp', async (req, res) => {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
        return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    try {
        console.log(`Sending OTP ${otp} to ${phone}...`);

        const message = await client.messages.create({
            body: `Your Farmer App OTP is: ${otp}`,
            from: twilioNumber,
            to: phone
        });

        console.log(`Message sent: ${message.sid}`);
        res.status(200).json({ success: true, sid: message.sid });
    } catch (error) {
        console.error('Twilio Error:', error);
        res.status(500).json({ error: error.message });
    }
});

const multer = require('multer');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Configure Multer for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir);
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});

const upload = multer({ storage: storage });

const db = require('./utils/jsonOfficerDB');

// === FARMER API ===

app.post('/predict', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
    }

    const { phone, cropIndex } = req.body; // Get context
    const imagePath = req.file.path;
    const pythonScript = 'predict_pytorch.py';

    const pythonProcess = spawn('python', [pythonScript, imagePath]);

    let dataString = '';
    let errorString = '';

    pythonProcess.stdout.on('data', (data) => {
        dataString += data.toString();
    });

    pythonProcess.stderr.on('data', (data) => {
        errorString += data.toString();
    });

    pythonProcess.on('close', (code) => {
        // Clean up uploaded file
        // fs.unlink(imagePath, (err) => { // Keep file if we need to show it to officer
        //     if (err) console.error("Error deleting temp file:", err);
        // });
        // Actually, we should move it to a permanent location if we want to keep it.
        // For now, let's assume 'uploads/' is public/static or we serve it.

        if (code !== 0) {
            console.error(`Python script exited with code ${code}`);
            console.error(`Stderr: ${errorString}`);
            return res.status(500).json({ error: 'Prediction failed', details: errorString });
        }

        try {
            const jsonResponse = JSON.parse(dataString.trim());

            // LOG DETECTION TO DB
            if (jsonResponse.status === 'Unhealthy') {
                let userLocation = 'Unknown';
                if (phone) {
                    const user = db.getUserByPhone(phone);
                    if (user && user.location) {
                        userLocation = user.location;
                    }
                }

                db.addReport({
                    disease: jsonResponse.detected,
                    confidence: jsonResponse.confidence,
                    location: userLocation,
                    image: req.file.filename,
                    reason: jsonResponse.reason,
                    preventiveMeasures: jsonResponse.preventive_measures
                });

                // UPDATE USER CROP IF CONTEXT PROVIDED
                if (phone && cropIndex !== undefined) {
                    db.updateUserCrop(phone, parseInt(cropIndex), {
                        health: 'Infected',
                        diseaseName: jsonResponse.detected,
                        preventiveMeasures: jsonResponse.preventive_measures || "Consult an expert.",
                        reason: jsonResponse.reason || "Fungal infection likely.",
                        imageUrl: req.file.filename
                    });
                }
            } else if (phone && cropIndex !== undefined) {
                // Update as Healthy if previously infected? Or just set checked status.
                db.updateUserCrop(phone, parseInt(cropIndex), {
                    health: 'Healthy',
                    diseaseName: null,
                    preventiveMeasures: null,
                    reason: null,
                    imageUrl: null
                });
            }

            res.json(jsonResponse);
        } catch (e) {
            console.error("Error parsing JSON:", e);
            console.error("Raw output:", dataString);
            res.status(500).json({ error: 'Invalid response from model', details: dataString });
        }
    });
});

// Serve static files from uploads directory
app.use('/uploads', express.static('uploads'));

app.get('/api/advisories', (req, res) => {
    const advisories = db.getAdvisories();
    res.json(advisories);
});


// === OFFICER API ===

app.get('/api/officer/stats', (req, res) => {
    const reports = db.getReports();

    // Aggregation Logic
    const diseaseCounts = {};
    reports.forEach(r => {
        diseaseCounts[r.disease] = (diseaseCounts[r.disease] || 0) + 1;
    });

    res.json({
        totalReports: reports.length,
        diseaseCounts: diseaseCounts,
        recentReports: reports.slice(-5).reverse() // Last 5
    });
});

app.delete('/api/officer/reports/:id', (req, res) => {
    const { id } = req.params;
    const success = db.deleteReport(id);
    if (success) {
        res.json({ success: true, message: "Report deleted" });
    } else {
        res.status(404).json({ error: "Report not found" });
    }
});

app.get('/api/officer/farmers', (req, res) => {
    const users = db.getUsers();
    const farmers = users.filter(u => u.role === 'farmer');
    res.json(farmers);
});

app.post('/api/officer/advisories', (req, res) => {
    const { title, message, targetRegion, severity } = req.body;
    if (!title || !message) return res.status(400).json({ error: "Missing fields" });

    const newAdvisory = db.addAdvisory({
        title,
        message,
        targetRegion: targetRegion || "All",
        severity: severity || "Info"
    });

    res.json(newAdvisory);
});

app.post('/api/register', (req, res) => {
    const { name, phone, role, location } = req.body;
    if (!phone || !role) return res.status(400).json({ error: "Missing required fields" });

    const users = db.getUsers();
    const existingUser = users.find(u => u.phone === phone);

    if (existingUser) {
        return res.status(400).json({ error: "User already exists" });
    }

    const newUser = {
        id: Date.now().toString(),
        name: name || "New User",
        phone,
        role,
        location: location || "Unknown", // Location from Geolocator
        joinedAt: new Date().toISOString()
    };

    // Add to DB (We need to add addUser method to utils first, or just read/write here)
    // Let's assume we add addUser to utils/jsonOfficerDB.js
    const success = db.addUser(newUser);

    if (success) {
        res.json({ success: true, user: newUser });
    } else {
        res.status(500).json({ error: "Failed to register user" });
    }
});

app.get('/api/user/:phone', (req, res) => {
    const { phone } = req.params;
    const user = db.getUserByPhone(phone);
    if (user) {
        res.json(user);
    } else {
        res.status(404).json({ error: "User not found" });
    }
});

app.post('/api/user/:phone/crops', (req, res) => {
    const { phone } = req.params;
    const cropData = req.body;

    if (!cropData || !cropData.name) {
        return res.status(400).json({ error: "Invalid crop data" });
    }

    const success = db.addCropToUser(phone, cropData);
    if (success) {
        res.json({ success: true, message: "Crop added successfully" });
    } else {
        res.status(404).json({ error: "User not found" });
    }
});

app.delete('/api/officer/advisories/:id', (req, res) => {
    const { id } = req.params;
    const success = db.deleteAdvisory(id);
    if (success) {
        res.json({ success: true, message: "Advisory deleted" });
    } else {
        res.status(404).json({ error: "Advisory not found" });
    }
});

app.listen(port, () => {
    console.log(`Backend server running at http://localhost:${port}`);
});
