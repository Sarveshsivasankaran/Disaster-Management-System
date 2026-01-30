const SUPABASE_URL = "https://nqipgzknhlfsrezssoyr.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5xaXBnemtuaGxmc3JlenNzb3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzNzQ4ODYsImV4cCI6MjA3Mzk1MDg4Nn0.M1xc6HtScdDjemguonpPgmo8EF0A93OoHvy4LACO24E";

const supabaseClient = supabase.createClient(
  SUPABASE_URL,
  SUPABASE_ANON_KEY
);

/* expose ONLY the client */
window.supabaseClient = supabaseClient;

console.log("Supabase client ready:", supabaseClient);
