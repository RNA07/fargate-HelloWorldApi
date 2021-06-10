const express = require("express");
const bodyParser = require('body-parser');
const port = process.env.PORT || 3001;

const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Enable CORS for all methods
app.use(function (req, res, next) {
    res.header("Access-Control-Allow-Origin", "*")
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
    next()
});

app.get("/", async (req, res, next) => {

    try {
        res.contentType("application/json").send({ 
            "Hello World! you are visotry number:": Math.floor(Math.random() * 101) 
        })
    } catch (err) {
        next(err);
    }
});

app.listen(port, () => {
    console.log('This hello world app is listening at http://localhost:' + port);
});