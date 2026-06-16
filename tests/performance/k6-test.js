// K6 load‑testing script for KubeWatch backend API
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 10, // 10 virtual users
  duration: '30s', // run for 30 seconds
};

export default function () {
  // Test health endpoint
  http.get('http://localhost:8090/api/v1/health');
  sleep(1);
  // Test status endpoint
  http.get('http://localhost:8090/api/v1/status');
  sleep(1);
}
