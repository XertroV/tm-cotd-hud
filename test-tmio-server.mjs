import express from 'express';
import _axios from 'axios';

const app = express();

const cache = {totd: null};

app.get('/totd/0', (req, res) => {
    console.info(`req for /totd/0`);
    res.send(JSON.stringify(cache.totd));
})

// const headers = {"User-Agent": "@XertroV's TMIO dev server -- testing caching"};
const headers = {"User-Agent": "@XertroV's TMIO dev server (this should only make unique requests on initialization)"};
const axios = _axios.create({headers});

const UpdateTotdValue = () => {
    axios.get('https://trackmania.io/api/totd/0')
        .then(resp => {
            cache.totd = resp.data;
            console.log(`Cached TOTD data. stringified length: ${JSON.stringify(cache.totd).length}`);
        })
        .catch(err => {
            console.error("Failed to get TM.IO TOTD data.", err);
            process.exit(1);
        })
    // how long till the hour?
    const currTime = (Date.now() / 1000) | 0;
    const tillNextHour = 3600 - (currTime % 3600);
    // call at 1 min past the hour
    setTimeout(UpdateTotdValue, (tillNextHour + 60) * 1000);
}

const port = 44444;
app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});

UpdateTotdValue();
