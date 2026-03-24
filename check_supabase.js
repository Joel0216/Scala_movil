const fs = require('fs');
const baseUrl = 'https://vqsduyfkgdqnigzkxazk.supabase.co/rest/v1';
const headers = {
  'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxc2R1eWZrZ2Rxbmlnemt4YXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzIyOTMsImV4cCI6MjA4NDYwODI5M30.l5bZubjb3PIvcFG43JTfoeguldEwwIK7wlnOnl-Ec5o',
  'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxc2R1eWZrZ2Rxbmlnemt4YXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzIyOTMsImV4cCI6MjA4NDYwODI5M30.l5bZubjb3PIvcFG43JTfoeguldEwwIK7wlnOnl-Ec5o',
  'Content-Type': 'application/json'
};

async function check() {
  const maestros = await fetch(`${baseUrl}/maestros?select=*`, { headers }).then(res => res.json());
  const grupos = await fetch(`${baseUrl}/grupos?select=*`, { headers }).then(res => res.json());
  fs.writeFileSync('supabase_data.json', JSON.stringify({ maestros, grupos }, null, 2));
}

check();
