/**
 * TempConv load test (k6)
 * Simulates many frontends calling the backend.
 * Run: k6 run k6-load.js
 * With base URL: k6 run -e BASE_URL=http://localhost:8080 k6-load.js
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const options = {
  stages: [
    { duration: '30s', target: 20 },   // Ramp up to 20 virtual users
    { duration: '1m', target: 20 },    // Stay at 20 users
    { duration: '30s', target: 50 },   // Ramp up to 50
    { duration: '1m', target: 50 },    // Stay at 50
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],   // Error rate under 1%
  },
};

export default function () {
  // Simulate C->F and F->C calls (like frontend users)
  const c2f = http.get(`${BASE_URL}/celsius-to-fahrenheit?value=25`);
  check(c2f, { 'c2f status 200': (r) => r.status === 200 });
  check(c2f, { 'c2f value 77': (r) => {
    try {
      const j = JSON.parse(r.body);
      return j.value === 77;
    } catch { return false; }
  }});

  const f2c = http.get(`${BASE_URL}/fahrenheit-to-celsius?value=212`);
  check(f2c, { 'f2c status 200': (r) => r.status === 200 });
  check(f2c, { 'f2c value 100': (r) => {
    try {
      const j = JSON.parse(r.body);
      return j.value === 100;
    } catch { return false; }
  }});

  sleep(0.5 + Math.random());
}
