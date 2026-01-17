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
};

module.exports = db;
