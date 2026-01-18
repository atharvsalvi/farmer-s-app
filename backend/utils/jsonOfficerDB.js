const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../data');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

const FILES = {
    REPORTS: path.join(DATA_DIR, 'reports.json'),
    ADVISORIES: path.join(DATA_DIR, 'advisories.json'),
    FARMERS: path.join(DATA_DIR, 'farmers.json'),
    USERS: path.join(DATA_DIR, 'users.json'),
};

// Initialize empty files if they don't exist
Object.values(FILES).forEach(filePath => {
    if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, JSON.stringify([], null, 2));
    }
});

const readJson = (filePath) => {
    try {
        const data = fs.readFileSync(filePath, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error(`Error reading ${filePath}:`, error);
        return [];
    }
};

const writeJson = (filePath, data) => {
    try {
        fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
        return true;
    } catch (error) {
        console.error(`Error writing to ${filePath}:`, error);
        return false;
    }
};

const db = {
    // REPORTS (Disease Detections)
    addReport: (report) => {
        const reports = readJson(FILES.REPORTS);
        report.id = Date.now().toString();
        report.timestamp = new Date().toISOString();
        reports.push(report);
        writeJson(FILES.REPORTS, reports);
        return report;
    },
    getReports: () => readJson(FILES.REPORTS),
    deleteReport: (id) => {
        let reports = readJson(FILES.REPORTS);
        const filtered = reports.filter(r => r.id !== id);
        if (filtered.length !== reports.length) {
            writeJson(FILES.REPORTS, filtered);
            return true;
        }
        return false;
    },

    // ADVISORIES
    addAdvisory: (advisory) => {
        const advisories = readJson(FILES.ADVISORIES);
        advisory.id = Date.now().toString();
        advisory.date = new Date().toISOString().split('T')[0];
        advisories.unshift(advisory); // Add to beginning
        writeJson(FILES.ADVISORIES, advisories);
        return advisory;
    },
    getAdvisories: () => readJson(FILES.ADVISORIES),

    deleteAdvisory: (id) => {
        let advisories = readJson(FILES.ADVISORIES);
        const filtered = advisories.filter(a => a.id !== id);
        if (filtered.length !== advisories.length) {
            writeJson(FILES.ADVISORIES, filtered);
            return true;
        }
        return false;
    },

    // USERS
    getUsers: () => readJson(FILES.USERS),
    getUserByPhone: (phone) => {
        const users = readJson(FILES.USERS);
        return users.find(u => u.phone === phone);
    },
    addUser: (user) => {
        const users = readJson(FILES.USERS);
        users.push(user);
        return writeJson(FILES.USERS, users);
    },
    addCropToUser: (phone, cropData) => {
        const users = readJson(FILES.USERS);
        const userIndex = users.findIndex(u => u.phone === phone);

        if (userIndex !== -1) {
            if (!users[userIndex].crops) {
                users[userIndex].crops = [];
            }
            users[userIndex].crops.push(cropData);
            return writeJson(FILES.USERS, users);
        }
        return false;
    },
    updateUserCrop: (phone, cropIndex, updateData) => {
        const users = readJson(FILES.USERS);
        const userIndex = users.findIndex(u => u.phone === phone);

        if (userIndex !== -1 && users[userIndex].crops && users[userIndex].crops[cropIndex]) {
            users[userIndex].crops[cropIndex] = {
                ...users[userIndex].crops[cropIndex],
                ...updateData
            };
            return writeJson(FILES.USERS, users);
        }
        return false;
    },
};

module.exports = db;
