import { check } from 'k6';
import { Counter } from 'k6/metrics';
import http from 'k6/http';
import { uuidv4 } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';

const successCounter = new Counter('success_counter');
const failedCounter = new Counter('failed_counter');

const payloads = JSON.parse(open('/scripts/loadtest/tokens.json'));
const randomIndex = Math.floor(Math.random() * payloads.length);
const payload = payloads[randomIndex];

export default function () {
    const params = {
        headers: {
            'X-Request-ID': uuidv4(),
            Authorization: payload.token,
        },
    };

    const serviceURL = __ENV.SERVICE_URL;
    const resp = http.get(serviceURL+'/list-vouchers', params);
    check(resp, {
        'contains expected username': (r) => r.status === 200 && r.json().user.username=== payload.username,
    });

    if (resp.status === 200) {
        successCounter.add(1);
    } else {
        failedCounter.add(1);
    }
}