/**
 * TempConv Load Test - k6
 * Tests gRPC endpoints under load (simulates many concurrent frontends/users)
 *
 * Run: k6 run loadtest/loadtest.js
 * With backend: BACKEND_URL=localhost:50051 k6 run loadtest/loadtest.js
 * Options: k6 run --vus 50 --duration 30s loadtest/loadtest.js
 */
import grpc from 'k6/net/grpc';
import { check, sleep } from 'k6';

const client = new grpc.Client();
// Proto must be in same dir or provide path; run from project root: k6 run loadtest/loadtest.js
client.load(['.'], 'tempconv.proto');

const BACKEND_URL = __ENV.BACKEND_URL || 'localhost:50051';

export const options = {
  stages: [
    { duration: '10s', target: 10 },
    { duration: '30s', target: 50 },
    { duration: '10s', target: 100 },
    { duration: '20s', target: 50 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    grpc_req_duration: ['p(95)<500'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  client.connect(BACKEND_URL, { plaintext: true });

  const useC2F = Math.random() > 0.5;
  const value = 20 + Math.random() * 30;
  const method = useC2F
    ? 'tempconv.TempConvService/CelsiusToFahrenheit'
    : 'tempconv.TempConvService/FahrenheitToCelsius';

  const response = client.invoke(method, { value });

  check(response, {
    'status is OK': (r) => r && r.status === grpc.StatusOK,
  });
  check(response, {
    'has value': (r) => r && r.message && r.message.value !== undefined,
  });

  client.close();
  sleep(0.5);
}
