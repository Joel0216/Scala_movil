const baseUrl = 'https://vqsduyfkgdqnigzkxazk.supabase.co/rest/v1';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxc2R1eWZrZ2Rxbmlnemt4YXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzIyOTMsImV4cCI6MjA4NDYwODI5M30.l5bZubjb3PIvcFG43JTfoeguldEwwIK7wlnOnl-Ec5o';
const headers = { 'apikey': key, 'Authorization': 'Bearer ' + key };

async function main() {
  // Buscar específicamente maestro con clave PO
  const res1 = await fetch(`${baseUrl}/maestros?select=id,nombre,clave,activo,email&clave=eq.PO`, { headers });
  const poClave = await res1.json();
  console.log('Maestro con clave PO:');
  console.log(JSON.stringify(poClave, null, 2));

  // Buscar por nombre POOL
  const res2 = await fetch(`${baseUrl}/maestros?select=id,nombre,clave,activo,email&nombre=ilike.*POOL*`, { headers });
  const poolNombre = await res2.json();
  console.log('\nMaestro con nombre POOL:');
  console.log(JSON.stringify(poolNombre, null, 2));

  // Todos con email no nulo
  const res3 = await fetch(`${baseUrl}/maestros?select=id,nombre,clave,activo,email&email=not.is.null`, { headers });
  const conEmail = await res3.json();
  console.log('\nTodos los maestros con email registrado:');
  console.log(JSON.stringify(conEmail, null, 2));
}
main().catch(console.error);
