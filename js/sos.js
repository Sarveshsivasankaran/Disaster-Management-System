async function sendSOS() {
  const name = document.getElementById("sosName").value.trim();
  const phone = document.getElementById("sosPhone").value.trim();
  const description = document.getElementById("sosMessage").value.trim();
  const locationText = document.getElementById("sosLocation").value.trim();

  if (!name || !phone || !description || !locationText) {
    alert("Please fill all fields before sending SOS.");
    return;
  }

  if (!/^\d{10}$/.test(phone)) {
    alert("Enter a valid 10-digit phone number.");
    return;
  }

  if (!navigator.geolocation) {
    alert("Geolocation not supported by your browser.");
    return;
  }

  navigator.geolocation.getCurrentPosition(
    async (position) => {
      const latitude = position.coords.latitude;
      const longitude = position.coords.longitude;

      const { data, error } = await window.supabaseClient
  .from("sos_alerts")
  .insert([
    {
      name,
      phone,
      latitude,
      longitude,
      description,
      location_text: locationText,
      status: "NEW"
    }
  ]);


      console.log("Supabase response:", data, error);

      if (error) {
        console.error(error);
        alert("Failed to send SOS. Try again.");
      } else {
        alert("SOS alert sent successfully!");
        document.getElementById("sosName").value = "";
        document.getElementById("sosPhone").value = "";
        document.getElementById("sosMessage").value = "";
        document.getElementById("sosLocation").value = "";
      }
    },
    () => {
      alert("Location permission is required to send SOS.");
    }
  );
}

function useCurrentLocation() {
  if (!navigator.geolocation) {
    alert("Geolocation not supported.");
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (position) => {
      const lat = position.coords.latitude.toFixed(6);
      const lng = position.coords.longitude.toFixed(6);

      document.getElementById("sosLocation").value =
        `Lat: ${lat}, Lng: ${lng}`;
    },
    () => {
      alert("Unable to fetch location.");
    }
  );
}
