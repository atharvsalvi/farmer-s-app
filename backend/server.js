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

app.listen(port, () => {
    console.log(`Backend server running at http://localhost:${port}`);
});
