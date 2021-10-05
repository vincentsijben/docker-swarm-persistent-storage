const express = require('express');
const app = express();
const path = require('path');

// Define paths for Express config
const publicDirectoryPath = path.join(__dirname, './public');

// Setup static directory to serve
app.use(express.static(publicDirectoryPath));

app.get("/", async (req, res) => {

    res.status(200).send("ok");
});

app.get('/healthz', function (req, res) {
    // do app logic here to determine if app is truly healthy
    // you should return 200 if healthy, and anything else will fail
    // if you want, you should be able to restrict this to localhost (include ipv4 and ipv6)
    const hostmachine = req.headers.host.split(':')[0];
    if (hostmachine !== 'localhost') return res.send(404);
    res.send('I am happy and healthy\n');
});
 
module.exports = app; 