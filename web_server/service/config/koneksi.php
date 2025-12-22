<!-- file koneksi database -->
 <?php
// Konfigurasi koneksi ke database
$host = "localhost"; // Host MySQL
$username = "soua3852_admin"; // Username MySQL
$password = "kemambuan"; // Password MySQL
$database = "soua3852_penjemputansdia28"; // Nama Database

// Buat koneksi ke database
$conn = mysqli_connect($host, $username, $password, $database);

// Periksa koneksi
if (!$conn) {
    die("Koneksi gagal: " . mysqli_connect_error());
}

// Jika koneksi berhasil
echo "Koneksi ke database berhasil";
?>