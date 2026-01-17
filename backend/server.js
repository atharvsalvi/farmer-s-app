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

app.post('/predict', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No image file uploaded' });
    }

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
        fs.unlink(imagePath, (err) => {
            if (err) console.error("Error deleting temp file:", err);
        });

        if (code !== 0) {
            console.error(`Python script exited with code ${code}`);
            console.error(`Stderr: ${errorString}`);
            return res.status(500).json({ error: 'Prediction failed', details: errorString });
        }

        try {
            const jsonResponse = JSON.parse(dataString.trim());
            res.json(jsonResponse);
        } catch (e) {
            console.error("Error parsing JSON:", e);
            console.error("Raw output:", dataString);
            res.status(500).json({ error: 'Invalid response from model', details: dataString });
        }
    });
});

app.listen(port, () => {
    console.log(`Backend server running at http://localhost:${port}`);
});
