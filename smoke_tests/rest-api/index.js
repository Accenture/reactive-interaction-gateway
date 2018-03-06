const express = require('express');
const morgan = require('morgan');
const bodyParser = require('body-parser');
const logger = require('winston');

// routes
const api = require('./src/routes/api');
const kafka = require('./src/routes/kafka');

const app = express();
const PORT = process.env.PORT || 8000;

// plugins
app.disable('etag');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(morgan('common'));

// routes
app.use('/api', api);
app.use('/kafka', kafka);

// catch 404 and forward to error handler
app.use((req, res, next) => {
    const err = new Error('Not Found');
    err.status = 404;
    next(err);
});

app.listen(PORT, () => logger.info(`Server started on port ${PORT}`));

module.exports = app;
